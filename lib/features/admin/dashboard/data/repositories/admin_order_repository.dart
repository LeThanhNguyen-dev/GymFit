import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/enums/database_enums.dart';
import '../../../../orders/data/models/order_model.dart';
import '../models/admin_dashboard_models.dart';

class AdminOrderRepository {
  const AdminOrderRepository(this._client);

  final SupabaseClient _client;

  Future<({List<OrderModel> items, int totalCount})> getAdminOrders({
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'created_at',
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    var query = _client.from(AppConstants.ordersTable).select();

    if (status != null) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('order_number', '%$search%');
    }
    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom);
    }
    if (dateTo != null) {
      query = query.lte('created_at', dateTo);
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => OrderModel.fromJson(row)).toList();

    var countQuery = _client.from(AppConstants.ordersTable).select('id');
    if (status != null) {
      countQuery = countQuery.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      countQuery = countQuery.ilike('order_number', '%$search%');
    }
    if (dateFrom != null) {
      countQuery = countQuery.gte('created_at', dateFrom);
    }
    if (dateTo != null) {
      countQuery = countQuery.lte('created_at', dateTo);
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
  }

  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? note,
    String? changedBy,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final statusMap = <String, dynamic>{
      'status': status.name,
      'updated_at': now,
    };

    switch (status) {
      case OrderStatus.confirmed:
        statusMap['confirmed_at'] = now;
      case OrderStatus.shipped:
        statusMap['shipped_at'] = now;
      case OrderStatus.delivered:
        statusMap['delivered_at'] = now;
      case OrderStatus.cancelled:
        statusMap['cancelled_at'] = now;
      default:
    }

    final row = await _client
        .from(AppConstants.ordersTable)
        .update(statusMap)
        .eq('id', orderId)
        .select()
        .single();

    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'status': status.name,
      'note': note,
      'changed_by': changedBy,
      'created_at': now,
    });

    return OrderModel.fromJson(row);
  }

  Future<DashboardStats> getDashboardStats() async {
    final todayStart = DateTime.now().toUtc().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      microsecond: 0,
      millisecond: 0,
    );

    final todayOrders = await _client
        .from(AppConstants.ordersTable)
        .select('id')
        .gte('created_at', todayStart.toIso8601String());

    final todayRevenue = await _client
        .from(AppConstants.ordersTable)
        .select('total_amount')
        .gte('created_at', todayStart.toIso8601String())
        .eq('status', 'delivered');

    final pendingOrders = await _client
        .from(AppConstants.ordersTable)
        .select('id')
        .eq('status', 'pending');

    final activeProducts = await _client
        .from(AppConstants.productsTable)
        .select('id')
        .eq('status', 'active');

    return DashboardStats(
      todayOrders: todayOrders.length,
      todayRevenue: todayRevenue.fold<double>(
        0,
        (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0),
      ),
      pendingOrders: pendingOrders.length,
      activeProducts: activeProducts.length,
    );
  }

  Future<List<OrderModel>> getRecentOrders({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.ordersTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) => OrderModel.fromJson(row)).toList();
  }
}
