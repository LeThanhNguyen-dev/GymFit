import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../shipping/presentation/screens/shipping_tracking_screen.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet don hang')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Khong tim thay don hang.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Trang thai',
                child: _StatusTimeline(order: order),
              ),
              _Section(
                title: 'Dia chi giao hang',
                child: Text(
                  '${order.shippingFullName} - ${order.shippingPhone}\n'
                  '${order.shippingAddress1}, ${order.shippingCity}',
                ),
              ),
              _Section(
                title: 'San pham',
                child: Column(
                  children: order.items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.variantInfo} x${item.quantity}',
                          ),
                          trailing: Text(formatCurrency(item.totalPrice)),
                        ),
                      )
                      .toList(),
                ),
              ),
              _Section(
                title: 'Thanh toan',
                child: Text(
                  '${order.payment?.methodDisplay ?? 'Chua co thong tin'}\n'
                  '${order.payment?.statusDisplay ?? ''}',
                ),
              ),
              _Section(
                title: 'Tong ket',
                child: Column(
                  children: [
                    _MoneyRow('Tam tinh', order.subtotal),
                    _MoneyRow('Giam gia', -order.discountAmount),
                    _MoneyRow('Phi van chuyen', order.shippingFee),
                    const Divider(),
                    _MoneyRow('Tong cong', order.totalAmount, isTotal: true),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ShippingTrackingScreen(orderId: order.id),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Theo doi don hang'),
              ),
              if (order.canCancel)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(orderListProvider.notifier)
                        .cancelOrder(order.id);
                    ref.invalidate(orderDetailProvider(order.id));
                  },
                  child: const Text('Huy don'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final current = statuses.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < statuses.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
              color: i <= current ? Colors.green : Colors.grey,
            ),
            title: Text(_statusText(statuses[i])),
          ),
      ],
    );
  }

  String _statusText(OrderStatus status) => switch (status) {
    OrderStatus.pending => 'Cho xac nhan',
    OrderStatus.confirmed => 'Da xac nhan',
    OrderStatus.processing => 'Dang xu ly',
    OrderStatus.shipped => 'Dang giao',
    OrderStatus.delivered => 'Da giao',
    _ => status.name,
  };
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
