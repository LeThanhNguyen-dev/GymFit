import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../data/repositories/payment_repository.dart';
import '../../orders/data/models/order_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(supabaseClientProvider));
});

final paymentProvider = FutureProvider.family<PaymentModel?, String>((
  ref,
  orderId,
) {
  return ref.watch(paymentRepositoryProvider).getPaymentByOrderId(orderId);
});

final paymentHistoryProvider = FutureProvider<List<PaymentModel>>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return const <PaymentModel>[];
  return ref.watch(paymentRepositoryProvider).getPaymentHistory(user.id);
});

final paymentProcessingProvider =
    AsyncNotifierProvider<PaymentProcessingNotifier, PaymentModel?>(
      PaymentProcessingNotifier.new,
    );

class PaymentProcessingNotifier extends AsyncNotifier<PaymentModel?> {
  @override
  Future<PaymentModel?> build() async => null;

  Future<PaymentModel> process(PaymentModel payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() {
      if (payment.method == PaymentMethod.momo) {
        return ref
            .read(paymentRepositoryProvider)
            .mockMomoPayment(payment.id, payment.amount);
      }
      if (payment.method == PaymentMethod.vnpay) {
        return ref
            .read(paymentRepositoryProvider)
            .mockVnPayPayment(payment.id, payment.amount);
      }
      return ref
          .read(paymentRepositoryProvider)
          .updatePaymentStatus(payment.id, PaymentStatus.pending);
    });
    state = result;
    return result.requireValue;
  }
}
