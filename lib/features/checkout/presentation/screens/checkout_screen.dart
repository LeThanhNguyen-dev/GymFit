import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../address/providers/address_providers.dart';
import '../../../payments/presentation/screens/payment_screen.dart';
import '../../providers/checkout_providers.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(defaultAddressProvider, (_, next) {
      final current = ref.read(selectedAddressProvider);
      final address = next.value;
      if (current == null && address != null) {
        ref.read(selectedAddressProvider.notifier).setAddress(address);
      }
    });

    final data = ref.watch(checkoutDataProvider);
    final address = ref.watch(selectedAddressProvider);
    final shippingFee = ref.watch(shippingFeeProvider).value ?? 30000;
    final total = ref.watch(checkoutTotalProvider);
    final createState = ref.watch(createOrderProvider);

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text('Chua co du lieu thanh toan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _Section(
            title: 'Dia chi giao hang',
            child: address == null
                ? FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Them dia chi'),
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(address.fullName),
                    subtitle: Text(
                      '${address.phone}\n${address.addressLine1}, ${address.city}',
                    ),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Thay doi'),
                    ),
                  ),
          ),
          _Section(
            title: 'San pham',
            child: Column(
              children: data.cartItems.map((item) {
                final product = item.product;
                final variant = item.variant;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product?.name ?? 'San pham'),
                  subtitle: Text(
                    '${variant?.optionDisplay ?? variant?.name ?? ''} x${item.quantity}',
                  ),
                  trailing: Text(formatCurrency(item.itemTotal)),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: 'Voucher',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(data.voucher?.code ?? 'Chua ap dung ma giam gia'),
              subtitle: data.discountAmount > 0
                  ? Text('-${formatCurrency(data.discountAmount)}')
                  : null,
            ),
          ),
          _Section(
            title: 'Phuong thuc thanh toan',
            child: RadioGroup<String>(
              groupValue: ref.watch(paymentMethodProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(paymentMethodProvider.notifier).setMethod(value);
                }
              },
              child: Column(
                children: const [
                  _PaymentRadio(
                    value: 'cod',
                    title: 'COD',
                    icon: Icons.payments,
                  ),
                  _PaymentRadio(
                    value: 'momo',
                    title: 'Momo',
                    icon: Icons.account_balance_wallet,
                  ),
                  _PaymentRadio(
                    value: 'vnpay',
                    title: 'VNPay',
                    icon: Icons.credit_card,
                  ),
                ],
              ),
            ),
          ),
          _Section(
            title: 'Ghi chu',
            child: TextField(
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ghi chu cho shop hoac don vi giao hang',
              ),
              onChanged: (value) {
                ref.read(orderNoteProvider.notifier).setNote(value);
              },
            ),
          ),
          _Section(
            title: 'Tong ket',
            child: Column(
              children: [
                _MoneyRow('Tam tinh', data.subtotal),
                _MoneyRow('Giam gia', -data.discountAmount),
                _MoneyRow('Phi van chuyen', shippingFee),
                const Divider(),
                _MoneyRow('Tong cong', total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatCurrency(total),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                onPressed: address == null || createState.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          final result = await ref
                              .read(createOrderProvider.notifier)
                              .submit();
                          if (!context.mounted) return;
                          if (result.paymentMethod == 'cod') {
                            await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Dat hang thanh cong'),
                                content: Text('Ma don: ${result.orderNumber}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Dong'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            navigator.push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PaymentScreen(orderId: result.orderId),
                              ),
                            );
                          }
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                child: createState.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Dat hang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _PaymentRadio extends StatelessWidget {
  const _PaymentRadio({
    required this.value,
    required this.title,
    required this.icon,
  });

  final String value;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      secondary: Icon(icon),
      title: Text(title),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount, {this.isTotal = false});

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatCurrency(amount), style: style),
        ],
      ),
    );
  }
}
