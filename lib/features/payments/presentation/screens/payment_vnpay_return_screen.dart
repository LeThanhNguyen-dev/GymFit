import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../providers/payment_providers.dart';

class PaymentVnPayReturnScreen extends ConsumerWidget {
  const PaymentVnPayReturnScreen({
    required this.queryParams,
    super.key,
  });

  final Map<String, String> queryParams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifyAsync = ref.watch(vnpayReturnProvider(queryParams));

    // Listen to changes to navigate automatically when done
    ref.listen(vnpayReturnProvider(queryParams), (previous, next) {
      next.whenData((payment) {
        if (context.mounted) {
          context.pushReplacementNamed(
            RouteNames.paymentStatus,
            extra: {
              'payment': payment,
              'orderId': payment.orderId,
            },
          );
        }
      });
      next.whenData((_) {}); // Just to silence unused
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang xử lý kết quả thanh toán'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: verifyAsync.when(
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xác thực kết quả từ VNPay...'),
            ],
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Có lỗi xảy ra: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final orderId = queryParams['order_id'];
                    if (orderId != null) {
                      context.pushReplacementNamed(
                        RouteNames.orderDetail,
                        pathParameters: {'id': orderId},
                      );
                    } else {
                      context.go(RouteNames.homePath);
                    }
                  },
                  child: const Text('Quay lại đơn hàng'),
                )
              ],
            ),
          ),
          data: (payment) => const SizedBox(), // Navigation handled in listen
        ),
      ),
    );
  }
}
