import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../orders/data/models/order_model.dart';

class ShippingRepository {
  const ShippingRepository(this._client);

  final SupabaseClient _client;

  Future<List<ShippingTrackingModel>> getTrackingByOrderId(
    String orderId,
  ) async {
    final rows = await _client
        .from(AppConstants.shippingTrackingTable)
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return rows.map((row) => ShippingTrackingModel.fromJson(row)).toList();
  }

  Future<ShippingTrackingModel?> getLatestTracking(String orderId) async {
    final row = await _client
        .from(AppConstants.shippingTrackingTable)
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : ShippingTrackingModel.fromJson(row);
  }

  Future<ShippingTrackingModel> createTrackingEvent(
    String orderId,
    ShippingStatus status, {
    String? location,
    String? note,
    DateTime? estimatedDelivery,
  }) async {
    final now = DateTime.now();
    final latest = await getLatestTracking(orderId);
    final event = {
      'status': status.name,
      'location': location,
      'note': note,
      'created_at': now.toIso8601String(),
    };

    if (latest == null) {
      final row = await _client
          .from(AppConstants.shippingTrackingTable)
          .insert({
            'order_id': orderId,
            'carrier': 'GymFit Express',
            'tracking_number': 'GF${now.millisecondsSinceEpoch}',
            'status': status.name,
            'estimated_delivery': estimatedDelivery?.toIso8601String(),
            'events': [event],
            'last_event_at': now.toIso8601String(),
          })
          .select()
          .single();
      return ShippingTrackingModel.fromJson(row);
    }

    final events = [...latest.events, event];
    final row = await _client
        .from(AppConstants.shippingTrackingTable)
        .update({
          'status': status.name,
          'estimated_delivery':
              estimatedDelivery?.toIso8601String() ??
              latest.estimatedDelivery?.toIso8601String(),
          'actual_delivery': status == ShippingStatus.delivered
              ? now.toIso8601String()
              : latest.actualDelivery?.toIso8601String(),
          'events': events,
          'last_event_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', latest.id)
        .select()
        .single();
    return ShippingTrackingModel.fromJson(row);
  }
}
