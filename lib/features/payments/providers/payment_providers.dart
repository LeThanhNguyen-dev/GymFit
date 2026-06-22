import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../../orders/data/models/order_model.dart';
import '../data/repositories/payment_repository.dart';

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

final payOsPaymentProvider =
    AsyncNotifierProvider<PayOsPaymentNotifier, PayOsPaymentSession?>(
      PayOsPaymentNotifier.new,
    );

final paymentProcessingProvider =
    AsyncNotifierProvider<PaymentProcessingNotifier, PaymentModel?>(
      PaymentProcessingNotifier.new,
    );

class PaymentProcessingNotifier extends AsyncNotifier<PaymentModel?> {
  @override
  Future<PaymentModel?> build() async => null;

  Future<PaymentModel> process(PaymentModel payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      if (payment.method == PaymentMethod.momo) {
        return ref
            .read(paymentRepositoryProvider)
            .mockMomoPayment(payment.id, payment.amount);
      }
      return ref
          .read(paymentRepositoryProvider)
          .updatePaymentStatus(payment.id, PaymentStatus.pending);
    });
    state = result;
    return result.requireValue;
  }
}

class PayOsPaymentNotifier extends AsyncNotifier<PayOsPaymentSession?> {
  @override
  Future<PayOsPaymentSession?> build() async => null;

  Future<PayOsPaymentSession> create(PaymentModel payment) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(paymentRepositoryProvider).createPayOsPayment(payment),
    );
    state = result;
    return result.requireValue;
  }

  Future<PaymentModel> sync(PaymentModel payment) {
    return ref.read(paymentRepositoryProvider).syncPayOsPayment(payment);
  }
}
