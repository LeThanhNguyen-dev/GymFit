import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../address/providers/address_providers.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../payments/presentation/screens/payment_screen.dart';
import '../../data/models/checkout_model.dart';
import '../../providers/checkout_providers.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, this.initialData});

  final CheckoutData? initialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialData != null && ref.read(checkoutDataProvider) == null) {
      Future.microtask(() {
        ref.read(checkoutDataProvider.notifier).setData(initialData);
      });
    }

    final data = ref.watch(checkoutDataProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    var address = ref.watch(selectedAddressProvider);

    if (address == null && addressesAsync.hasValue && addressesAsync.value!.isNotEmpty) {
      address = addressesAsync.value!.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressesAsync.value!.first,
      );
      Future.microtask(() {
         ref.read(selectedAddressProvider.notifier).setAddress(address);
      });
    }
    final shippingFee = ref.watch(shippingFeeProvider).value ?? 30000;
    final total = ref.watch(checkoutTotalProvider);
    final createState = ref.watch(createOrderProvider);

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text('Chưa có dữ liệu thanh toán.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _Section(
            title: 'Địa chỉ giao hàng',
            child: address == null
                ? FilledButton.icon(
                    onPressed: () => context.push('/addresses'),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Thêm địa chỉ'),
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(address.fullName),
                    subtitle: Text(
                      '${address.phone}\n${address.addressLine1}, ${address.city}',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push('/addresses'),
                      child: const Text('Thay đổi'),
                    ),
                  ),
          ),
          _Section(
            title: 'Sản phẩm',
            child: Column(
              children: data.cartItems.map((item) {
                final product = item.product;
                final variant = item.variant;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product?.name ?? 'Sản phẩm'),
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
              title: Text(data.voucher?.code ?? 'Chưa áp dụng mã giảm giá'),
              subtitle: data.discountAmount > 0
                  ? Text('-${formatCurrency(data.discountAmount)}')
                  : null,
            ),
          ),
          _Section(
            title: 'Phương thức thanh toán',
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
            title: 'Ghi chú',
            child: TextField(
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ghi chú cho shop hoặc đơn vị giao hàng',
              ),
              onChanged: (value) {
                ref.read(orderNoteProvider.notifier).setNote(value);
              },
            ),
          ),
          _Section(
            title: 'Tổng kết',
            child: Column(
              children: [
                _MoneyRow('Tạm tính', data.subtotal),
                _MoneyRow('Giảm giá', -data.discountAmount),
                _MoneyRow('Phí vận chuyển', shippingFee),
                const Divider(),
                _MoneyRow('Tổng cộng', total, isTotal: true),
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
                            ref.read(cartItemsProvider.notifier).clearCart();
                            await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Đặt hàng thành công'),
                                content: Text('Mã đơn: ${result.orderNumber}'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Đóng'),
                                  ),
                                ],
                              ),
                            );
                            if (context.mounted) {
                              context.go('/');
                            }
                          } else {
                            ref.read(cartItemsProvider.notifier).clearCart();
                            navigator.pushReplacement(
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
                    : const Text('Đặt hàng'),
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
