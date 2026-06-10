import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../providers/payment_providers.dart';
import 'payment_status_screen.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentProvider(orderId));
    final processing = ref.watch(paymentProcessingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toan')),
      body: payment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Khong tim thay thanh toan.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  payment.method == PaymentMethod.momo
                      ? Icons.account_balance_wallet
                      : payment.method == PaymentMethod.vnpay
                      ? Icons.credit_card
                      : Icons.payments,
                  size: 72,
                  color: payment.method == PaymentMethod.momo
                      ? Colors.pink
                      : Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  payment.methodDisplay,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(payment.amount),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (payment.method == PaymentMethod.vnpay)
                  const DropdownMenu<String>(
                    initialSelection: 'vcb',
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: 'vcb', label: 'Vietcombank'),
                      DropdownMenuEntry(value: 'tcb', label: 'Techcombank'),
                      DropdownMenuEntry(value: 'mb', label: 'MB Bank'),
                    ],
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: processing.isLoading
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final result = await ref
                              .read(paymentProcessingProvider.notifier)
                              .process(payment);
                          if (!context.mounted) return;
                          navigator.pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => PaymentStatusScreen(
                                payment: result,
                                orderId: orderId,
                              ),
                            ),
                          );
                        },
                  child: processing.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          payment.method == PaymentMethod.cod
                              ? 'Xac nhan'
                              : 'Xac nhan thanh toan',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
