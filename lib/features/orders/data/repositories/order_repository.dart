import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/enums/database_enums.dart';
import '../models/order_model.dart';

class OrderRepository {
  const OrderRepository(this._client);

  final SupabaseClient _client;

  static const _orderSelect =
      '*, items:order_items(*), payments(*), '
      'shipping_tracking(*), status_history:order_status_history(*)';

  Future<List<OrderModel>> getOrders(
    String userId, {
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client
        .from(AppConstants.ordersTable)
        .select(_orderSelect)
        .eq('user_id', userId);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize - 1);
    return rows.map((row) => OrderModel.fromJson(row)).toList();
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final row = await _client
        .from(AppConstants.ordersTable)
        .select(_orderSelect)
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : OrderModel.fromJson(row);
  }

  Future<void> cancelOrder(String orderId, String userId) async {
    final order = await getOrderById(orderId);
    if (order == null || order.userId != userId) {
      throw StateError('Khong tim thay don hang.');
    }
    if (!order.canCancel) {
      throw StateError('Don hang nay khong the huy.');
    }

    await _client
        .from(AppConstants.ordersTable)
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'from_status': order.status.name,
      'to_status': 'cancelled',
      'changed_by': userId,
      'note': 'Khach hang huy don',
    });

    for (final item in order.items) {
      if (item.variantId == null) continue;
      await _increaseVariantStock(item.variantId!, item.quantity);
    }
  }

  Future<List<OrderStatusHistoryModel>> getOrderStatusHistory(
    String orderId,
  ) async {
    final rows = await _client
        .from('order_status_history')
        .select()
        .eq('order_id', orderId)
        .order('created_at');
    return rows.map((row) => OrderStatusHistoryModel.fromJson(row)).toList();
  }

  Future<Map<String, dynamic>?> getOrderSummary(String userId) async {
    return _client
        .from('v_user_order_summary')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<List<OrderModel>> getAllOrders({
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client.from(AppConstants.ordersTable).select(_orderSelect);
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize - 1);
    return rows.map((row) => OrderModel.fromJson(row)).toList();
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
    String adminId, {
    String? note,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw StateError('Khong tim thay don hang.');
    final now = DateTime.now();
    final statusValue = _statusValue(newStatus);
    final update = <String, dynamic>{
      'status': statusValue,
      'updated_at': now.toIso8601String(),
      if (newStatus == OrderStatus.confirmed)
        'confirmed_at': now.toIso8601String(),
      if (newStatus == OrderStatus.shipped) 'shipped_at': now.toIso8601String(),
      if (newStatus == OrderStatus.delivered)
        'delivered_at': now.toIso8601String(),
      if (newStatus == OrderStatus.cancelled)
        'cancelled_at': now.toIso8601String(),
    };

    await _client
        .from(AppConstants.ordersTable)
        .update(update)
        .eq('id', orderId);
    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'from_status': _statusValue(order.status),
      'to_status': statusValue,
      'changed_by': adminId,
      'note': note,
    });

    if (newStatus == OrderStatus.shipped) {
      await _client.from(AppConstants.shippingTrackingTable).insert({
        'order_id': orderId,
        'carrier': 'GymFit Express',
        'tracking_number': 'GF${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'events': [
          {
            'status': 'preparing',
            'note': 'Don hang dang duoc chuan bi',
            'created_at': now.toIso8601String(),
          },
        ],
        'last_event_at': now.toIso8601String(),
      });
    }

    if (newStatus == OrderStatus.delivered) {
      await _client
          .from('order_items')
          .update({'store_status': 'delivered', 'store_status_updated_at': now.toIso8601String()})
          .eq('order_id', orderId);

      final latest = await _client
          .from(AppConstants.shippingTrackingTable)
          .select('id, events')
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (latest != null) {
        final events =
            List<Map<String, dynamic>>.from(
              (latest['events'] as List?) ?? const [],
            )..add({
              'status': 'delivered',
              'note': 'Don hang da giao thanh cong',
              'created_at': now.toIso8601String(),
            });
        await _client
            .from(AppConstants.shippingTrackingTable)
            .update({
              'status': 'delivered',
              'events': events,
              'actual_delivery': now.toIso8601String(),
              'last_event_at': now.toIso8601String(),
            })
            .eq('id', latest['id']);
      }
    }
  }

  Future<void> customerConfirmDelivery(String orderId, String userId) async {
    await _client.rpc('customer_confirm_delivery', params: {
      'p_order_id': orderId,
      'p_user_id': userId,
    });
  }

  Future<void> _increaseVariantStock(String variantId, int quantity) async {
    final row = await _client
        .from('product_variants')
        .select('quantity, stock')
        .eq('id', variantId)
        .single();
    final current = ((row['quantity'] ?? row['stock']) as num?)?.toInt() ?? 0;
    await _client
        .from('product_variants')
        .update({
          'quantity': current + quantity,
          'stock': current + quantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', variantId);
  }

  String _statusValue(OrderStatus status) {
    return status == OrderStatus.shipped ? 'shipped' : status.name;
  }
}
