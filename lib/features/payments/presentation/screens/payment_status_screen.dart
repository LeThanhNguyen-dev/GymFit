import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/screens/order_detail_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Ket qua thanh toan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              size: 96,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Thanh toan thanh cong!' : 'Thanh toan that bai',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Ma don: $orderId\n'
              'So tien: ${formatCurrency(payment.amount)}\n'
              'Phuong thuc: ${payment.methodDisplay}',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailScreen(orderId: orderId),
                  ),
                );
              },
              child: const Text('Xem don hang'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Tiep tuc mua sam'),
            ),
          ],
        ),
      ),
    );
  }
}
