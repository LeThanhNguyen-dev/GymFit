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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc();
    final weekStart = now.subtract(const Duration(days: 7)).toUtc();
    final monthStart = now.subtract(const Duration(days: 30)).toUtc();

    // 1. Fetch recent orders for periods & daily revenue lines
    final recentOrders = await _client
        .from(AppConstants.ordersTable)
        .select('created_at, total_amount, status')
        .gte('created_at', monthStart.toIso8601String());

    // 2. Fetch all orders status for pie chart
    final allOrdersStatus = await _client
        .from(AppConstants.ordersTable)
        .select('status');

    // 3. Fetch active products
    final activeProducts = await _client
        .from(AppConstants.productsTable)
        .select('id')
        .eq('status', 'active');

    // 4. Fetch profiles for growth chart
    final userProfiles = await _client
        .from('profiles')
        .select('created_at');

    // 5. Fetch approved shops and order items of delivered orders
    final approvedShops = await _client
        .from('shop_registrations')
        .select('user_id, shop_name')
        .eq('status', 'approved');

    final deliveredOrders = await _client
        .from('orders')
        .select('id, order_items(total_price, product:products(seller_id))')
        .eq('status', 'delivered');

    // -- Calculate stats grids
    int tOrders = 0;
    double tRevenue = 0.0;
    int wOrders = 0;
    double wRevenue = 0.0;
    int mOrders = 0;
    double mRevenue = 0.0;

    for (final order in recentOrders) {
      final createdAtStr = order['created_at']?.toString();
      if (createdAtStr == null) continue;
      final createdAt = DateTime.parse(createdAtStr);
      final totalAmt = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final status = order['status']?.toString();

      if (createdAt.isAfter(todayStart)) {
        tOrders++;
        if (status == 'delivered') {
          tRevenue += totalAmt;
        }
      }
      if (createdAt.isAfter(weekStart)) {
        wOrders++;
        if (status == 'delivered') {
          wRevenue += totalAmt;
        }
      }
      if (createdAt.isAfter(monthStart)) {
        mOrders++;
        if (status == 'delivered') {
          mRevenue += totalAmt;
        }
      }
    }

    int pendingCount = 0;
    final Map<String, int> statusCounts = {};
    for (final order in allOrdersStatus) {
      final status = order['status']?.toString() ?? 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      if (status == 'pending') {
        pendingCount++;
      }
    }

    // -- Line chart (30 days daily revenue)
    final List<double> dailyRevenue30Days = List<double>.filled(30, 0.0);
    for (var i = 0; i < 30; i++) {
      final dayDate = now.subtract(Duration(days: 29 - i));
      final startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      double dailySum = 0;
      for (final order in recentOrders) {
        if (order['status'] == 'delivered') {
          final orderTime = DateTime.parse(order['created_at']?.toString() ?? '').toLocal();
          if (orderTime.isAfter(startOfDay) && orderTime.isBefore(endOfDay)) {
            dailySum += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
      dailyRevenue30Days[i] = dailySum;
    }

    // -- Top shops
    final Map<String, double> sellerRevenues = {};
    for (final order in deliveredOrders) {
      final itemsList = order['order_items'] as List?;
      if (itemsList == null) continue;
      for (final item in itemsList) {
        final totalPrice = (item['total_price'] as num?)?.toDouble() ?? 0.0;
        final product = (item['product'] ?? item['products']) as Map?;
        final sellerId = product?['seller_id']?.toString();
        if (sellerId != null) {
          sellerRevenues[sellerId] = (sellerRevenues[sellerId] ?? 0.0) + totalPrice;
        }
      }
    }

    final List<ShopRevenue> topShops = [];
    final approvedShopsMap = {
      for (final shop in approvedShops)
        shop['user_id']?.toString() ?? '': shop['shop_name']?.toString() ?? 'Shop'
    };

    approvedShopsMap.forEach((sellerId, shopName) {
      final rev = sellerRevenues[sellerId] ?? 0.0;
      topShops.add(ShopRevenue(shopName: shopName, revenue: rev));
    });

    topShops.sort((a, b) => b.revenue.compareTo(a.revenue));
    final displayShops = topShops.take(10).toList();

    // -- Monthly Growth (12 months)
    final List<MonthlyGrowth> monthlyUserGrowth = [];
    final List<DateTime> months = [];
    for (var i = 11; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    for (final month in months) {
      final endOfMonth = DateTime(month.year, month.month + 1, 1).subtract(const Duration(microseconds: 1));
      int count = 0;
      for (final profile in userProfiles) {
        final createdAtStr = profile['created_at']?.toString();
        if (createdAtStr != null) {
          final profileTime = DateTime.parse(createdAtStr).toLocal();
          if (profileTime.isBefore(endOfMonth)) {
            count++;
          }
        }
      }
      final monthLabel = '${month.month.toString().padLeft(2, '0')}/${month.year.toString().substring(2)}';
      monthlyUserGrowth.add(MonthlyGrowth(month: monthLabel, count: count));
    }

    return DashboardStats(
      todayOrders: tOrders,
      todayRevenue: tRevenue,
      weekOrders: wOrders,
      weekRevenue: wRevenue,
      monthOrders: mOrders,
      monthRevenue: mRevenue,
      pendingOrders: pendingCount,
      activeProducts: activeProducts.length,
      dailyRevenue30Days: dailyRevenue30Days,
      ordersByStatus: statusCounts,
      topShops: displayShops,
      monthlyUserGrowth: monthlyUserGrowth,
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
