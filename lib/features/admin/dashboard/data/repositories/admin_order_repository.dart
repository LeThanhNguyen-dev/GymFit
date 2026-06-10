import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/enums/database_enums.dart';
import '../../../../orders/data/models/order_model.dart';
import '../models/admin_dashboard_models.dart';

class AdminOrderRepository {
  const AdminOrderRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardStats> getDashboardStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final ordersToday = await _client
        .from(AppConstants.ordersTable)
        .select('id,total_amount')
        .gte('created_at', startOfDay);
    final pendingOrders = await _client
        .from(AppConstants.ordersTable)
        .select('id')
        .eq('status', 'pending');
    final activeProducts = await _client
        .from(AppConstants.productsTable)
        .select('id')
        .or('status.eq.active,is_active.eq.true');

    final revenue = ordersToday.fold<double>(
      0,
      (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return DashboardStats(
      todayOrders: ordersToday.length,
      todayRevenue: revenue,
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

  Future<List<OrderModel>> getAdminOrders({String? status}) async {
    final rows = await _client
        .from(AppConstants.ordersTable)
        .select()
        .order('created_at', ascending: false);

    return rows
        .map((row) => OrderModel.fromJson(row))
        .where((order) => status == null || order.status.name == status)
        .toList();
  }

  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? note,
    String? changedBy,
  }) async {
    final existing = await _client
        .from(AppConstants.ordersTable)
        .select('status')
        .eq('id', orderId)
        .single();
    final fromStatus = existing['status']?.toString();
    final toStatus = enumToSnake(status);
    final now = DateTime.now().toIso8601String();

    final row = await _client
        .from(AppConstants.ordersTable)
        .update({
          'status': toStatus,
          'updated_at': now,
          if (status == OrderStatus.shipped) 'shipped_at': now,
          if (status == OrderStatus.delivered) 'delivered_at': now,
          if (status == OrderStatus.cancelled) 'cancelled_at': now,
        })
        .eq('id', orderId)
        .select()
        .single();

    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'note': note,
      'changed_by': changedBy,
    });

    if (status == OrderStatus.shipped) {
      await _client.from(AppConstants.shippingTrackingTable).insert({
        'order_id': orderId,
        'carrier': 'Manual',
        'tracking_number': 'PENDING',
        'status': 'in_transit',
        'events': [
          {'status': 'shipping', 'note': note, 'created_at': now},
        ],
      });
    }

    return OrderModel.fromJson(row);
  }
}
