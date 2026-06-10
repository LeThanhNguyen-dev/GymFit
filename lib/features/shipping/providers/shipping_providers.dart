import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/repositories/shipping_repository.dart';
import '../../orders/data/models/order_model.dart';

final shippingRepositoryProvider = Provider<ShippingRepository>((ref) {
  return ShippingRepository(ref.watch(supabaseClientProvider));
});

final shippingTrackingProvider =
    FutureProvider.family<List<ShippingTrackingModel>, String>((ref, orderId) {
      return ref
          .watch(shippingRepositoryProvider)
          .getTrackingByOrderId(orderId);
    });

final latestShippingTrackingProvider =
    FutureProvider.family<ShippingTrackingModel?, String>((ref, orderId) {
      return ref.watch(shippingRepositoryProvider).getLatestTracking(orderId);
    });
