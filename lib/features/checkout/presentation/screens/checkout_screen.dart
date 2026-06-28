import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../address/providers/address_providers.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../data/models/checkout_model.dart';
import '../../providers/checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.initialData});

  final CheckoutData? initialData;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initCheckoutData();
    });
  }

  void _initCheckoutData() {
    if (_didInit) return;
    _didInit = true;
    if (widget.initialData != null) {
      ref.read(checkoutDataProvider.notifier).setData(widget.initialData);
      return;
    }

    if (ref.read(checkoutDataProvider) != null) return;

    final cartItems = ref.read(cartItemsProvider).asData?.value;
    if (cartItems != null && cartItems.isNotEmpty) {
      final subtotal = cartItems.fold<double>(
        0,
        (sum, item) => sum + item.itemTotal,
      );
      ref.read(checkoutDataProvider.notifier).setData(
        CheckoutData(
          cartItems: cartItems,
          source: CheckoutSource.cart,
          cartItemIds: cartItems.map((item) => item.id).toList(),
          subtotal: subtotal,
          discountAmount: 0,
          total: subtotal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(checkoutDataProvider);
    ref.watch(cartItemsProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    var address = ref.watch(selectedAddressProvider);

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initCheckoutData();
      });
    }

    if (address == null &&
        addressesAsync.hasValue &&
        addressesAsync.value!.isNotEmpty) {
      address = addressesAsync.value!.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressesAsync.value!.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedAddressProvider.notifier).setAddress(address);
        }
      });
    }

    final shippingFee = ref.watch(shippingFeeProvider).value ?? 30000;
    final total = ref.watch(checkoutTotalProvider);
    final createState = ref.watch(createOrderProvider);

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const _CheckoutShimmer(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 120,
        ),
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
            title: data.isBuyNow ? 'Sản phẩm mua ngay' : 'Sản phẩm đã chọn',
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
            child: Column(
              children: [
                _VoucherLine(
                  label: 'Voucher admin',
                  voucherCode: data.voucher?.code,
                ),
                const Divider(height: 16),
                _VoucherLine(
                  label: 'Voucher shop',
                  voucherCode: data.shopVoucher?.code,
                ),
                if (data.isBuyNow) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mua ngay không tự áp dụng voucher từ giỏ hàng.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else if (data.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('-${formatCurrency(data.discountAmount)}'),
                  ),
                ],
              ],
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
                    value: 'payos',
                    title: 'payOS / VietQR',
                    icon: Icons.qr_code_2,
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
                _MoneyRow('Tổng cộng dự kiến', total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(blurRadius: 12, color: Colors.black12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatCurrency(total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: address == null ||
                        data.cartItems.isEmpty ||
                        createState.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final checkoutData = data;
                        try {
                          final result = await ref
                              .read(createOrderProvider.notifier)
                              .submit();
                          if (!context.mounted) return;
                          if (checkoutData.isCartCheckout) {
                            await ref.read(cartItemsProvider.notifier).loadCart();
                          }
                          ref.read(checkoutDataProvider.notifier).setData(null);
                          if (result.paymentMethod == 'cod') {
                            if (context.mounted) {
                              context.go('/orders/${result.orderId}');
                            }
                          } else {
                            context.pushReplacementNamed(
                              RouteNames.payment,
                              pathParameters: {'orderId': result.orderId},
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

class _VoucherLine extends StatelessWidget {
  const _VoucherLine({required this.label, this.voucherCode});

  final String label;
  final String? voucherCode;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_offer_outlined),
      title: Text(label),
      subtitle: Text(voucherCode ?? 'Chưa áp dụng'),
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

class _CheckoutShimmer extends StatelessWidget {
  const _CheckoutShimmer();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: List.generate(
        5,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
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
