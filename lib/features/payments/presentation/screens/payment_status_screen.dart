import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../orders/data/models/order_model.dart';

class PaymentStatusScreen extends StatelessWidget {
  const PaymentStatusScreen({
    required this.payment,
    required this.orderId,
    super.key,
  });

  final PaymentModel payment;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final success = payment.status == PaymentStatus.paid;
    final pending = payment.status == PaymentStatus.pending;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              success
                  ? Icons.check_circle
                  : pending
                      ? Icons.hourglass_empty
                      : Icons.cancel,
              size: 96,
              color: success
                  ? Colors.green
                  : pending
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              success
                  ? 'Thanh toán thành công!'
                  : pending
                      ? 'Thanh toán đang chờ xử lý'
                      : 'Thanh toán thất bại',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Mã đơn: $orderId\n'
              'Số tiền: ${formatCurrency(payment.amount)}\n'
              'Phương thức: ${payment.methodDisplay}',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                context.pushReplacementNamed(
                  RouteNames.orderDetail,
                  pathParameters: {'id': orderId},
                );
              },
              child: const Text('Xem don hang'),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.homePath),
              child: const Text('Tiep tuc mua sam'),
            ),
          ],
        ),
      ),
    );
  }
}
