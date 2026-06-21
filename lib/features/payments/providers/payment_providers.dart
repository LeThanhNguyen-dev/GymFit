import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/vnpay_service.dart';

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
    final result = await AsyncValue.guard(() async {
      if (payment.method == PaymentMethod.momo) {
        return ref
            .read(paymentRepositoryProvider)
            .mockMomoPayment(payment.id, payment.amount);
      }
      if (payment.method == PaymentMethod.vnpay) {
        final vnpayService = VnPayService();
        final url = vnpayService.createPaymentUrl(
          amount: payment.amount.toInt(),
          orderInfo: 'Thanh toan don hang ${payment.orderId}',
          returnUrl: 'gymfit://app/payment-vnpay-return?payment_id=${payment.id}&order_id=${payment.orderId}',
          txnRef: payment.id.replaceAll('-', ''), // VNPay chỉ nhận [a-zA-Z0-9]
        );

        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        
        // Cập nhật trạng thái thành pending, hệ thống có thể poll hoặc xử lý qua deep link sau
        return ref
            .read(paymentRepositoryProvider)
            .updatePaymentStatus(payment.id, PaymentStatus.pending);
      }
      return ref
          .read(paymentRepositoryProvider)
          .updatePaymentStatus(payment.id, PaymentStatus.pending);
    });
    state = result;
    return result.requireValue;
  }
}

final vnpayReturnProvider = FutureProvider.family<PaymentModel, Map<String, String>>((ref, queryParams) async {
  final vnpayService = VnPayService();
  final isValid = vnpayService.verifyPaymentReturn(queryParams);
  
  final paymentId = queryParams['payment_id'];
  if (paymentId == null) {
    throw Exception('Khong tim thay ma thanh toan trong URL tra ve');
  }

  final responseCode = queryParams['vnp_ResponseCode'];
  final repo = ref.read(paymentRepositoryProvider);

  if (isValid && responseCode == '00') {
    return repo.updatePaymentStatus(paymentId, PaymentStatus.paid);
  } else {
    return repo.updatePaymentStatus(paymentId, PaymentStatus.failed);
  }
});
