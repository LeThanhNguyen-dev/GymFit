import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../orders/data/models/order_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../providers/payment_providers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _payOsRequestedPaymentId;

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(paymentProvider(widget.orderId));
    final processing = ref.watch(paymentProcessingProvider);
    final payOsSession = ref.watch(payOsPaymentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toan')),
      body: payment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Khong tim thay thanh toan.'));
          }
          if (payment.method == PaymentMethod.payos &&
              payment.status == PaymentStatus.pending) {
            _ensurePayOsSession(payment);
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  payment.method == PaymentMethod.momo
                      ? Icons.account_balance_wallet
                      : payment.method == PaymentMethod.payos
                      ? Icons.qr_code_2
                      : Icons.payments,
                  size: 72,
                  color: payment.method == PaymentMethod.momo
                      ? Colors.pink
                      : payment.method == PaymentMethod.payos
                      ? Colors.green
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
                if (payment.method == PaymentMethod.payos)
                  Expanded(
                    child: payOsSession.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _PayOsErrorPanel(
                        error: error.toString(),
                        onRetry: () => _createPayOsSession(payment),
                      ),
                      data: (session) => session == null
                          ? Center(
                              child: FilledButton.icon(
                                onPressed: () => _createPayOsSession(payment),
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text('Tao ma QR payOS'),
                              ),
                            )
                          : _PayOsPaymentPanel(
                              session: session,
                              onCopy: _copyPayOsInfo,
                            ),
                    ),
                  ),
                if (payment.method != PaymentMethod.payos) const Spacer(),
                FilledButton(
                  onPressed: processing.isLoading
                      ? null
                      : () async {
                          if (payment.method == PaymentMethod.payos) {
                            await _checkPayOsPayment(payment);
                            return;
                          }
                          final result = await ref
                              .read(paymentProcessingProvider.notifier)
                              .process(payment);
                          if (!context.mounted) return;
                          context.pushReplacementNamed(
                            RouteNames.paymentStatus,
                            extra: {
                              'payment': result,
                              'orderId': widget.orderId,
                            },
                          );
                        },
                  child: processing.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          payment.method == PaymentMethod.payos
                              ? 'Toi da thanh toan'
                              : payment.method == PaymentMethod.cod
                              ? 'Xac nhan'
                              : 'Xac nhan thanh toan',
                        ),
                ),
                if (payment.method == PaymentMethod.payos)
                  TextButton(
                    onPressed: () => _createPayOsSession(payment),
                    child: const Text('Tao lai ma QR'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _ensurePayOsSession(PaymentModel payment) {
    if (_payOsRequestedPaymentId == payment.id) return;
    _payOsRequestedPaymentId = payment.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _createPayOsSession(payment);
      }
    });
  }

  Future<void> _createPayOsSession(PaymentModel payment) async {
    try {
      await ref.read(payOsPaymentProvider.notifier).create(payment);
      ref.invalidate(paymentProvider(widget.orderId));
    } catch (_) {
      // The provider already exposes the error state to the UI.
    }
  }

  Future<void> _checkPayOsPayment(PaymentModel payment) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updatedPayment = await ref
          .read(payOsPaymentProvider.notifier)
          .sync(payment);
      ref.invalidate(paymentProvider(widget.orderId));
      if (!mounted) return;
      if (updatedPayment.status == PaymentStatus.paid ||
          updatedPayment.status == PaymentStatus.failed) {
        context.pushReplacementNamed(
          RouteNames.paymentStatus,
          extra: {'payment': updatedPayment, 'orderId': widget.orderId},
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Chua nhan duoc thanh toan payOS.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _copyPayOsInfo(PayOsPaymentSession session) async {
    final lines = [
      if (session.accountName != null) 'Ten TK: ${session.accountName}',
      if (session.accountNumber != null) 'So TK: ${session.accountNumber}',
      'So tien: ${formatCurrency(session.amount)}',
      'Noi dung: ${session.description}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da sao chep thong tin thanh toan.')),
    );
  }
}

class _PayOsPaymentPanel extends StatelessWidget {
  const _PayOsPaymentPanel({required this.session, required this.onCopy});

  final PayOsPaymentSession session;
  final ValueChanged<PayOsPaymentSession> onCopy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: QrImageView(
              data: session.qrCode,
              version: QrVersions.auto,
              size: 230,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PayOsInfoRow('So tien', formatCurrency(session.amount)),
                _PayOsInfoRow('Noi dung', session.description),
                if (session.accountName != null)
                  _PayOsInfoRow('Chu tai khoan', session.accountName!),
                if (session.accountNumber != null)
                  _PayOsInfoRow('So tai khoan', session.accountNumber!),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => onCopy(session),
          icon: const Icon(Icons.copy),
          label: const Text('Sao chep thong tin chuyen khoan'),
        ),
        const SizedBox(height: 8),
        Text(
          'Mo ung dung ngan hang va quet QR de thanh toan. Sau khi chuyen khoan, bam "Toi da thanh toan" de cap nhat trang thai.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PayOsInfoRow extends StatelessWidget {
  const _PayOsInfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayOsErrorPanel extends StatelessWidget {
  const _PayOsErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thu lai')),
        ],
      ),
    );
  }
}
