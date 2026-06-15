import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_providers.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    final notifier = ref.read(orderListProvider.notifier);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Don hang'),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) => notifier.setStatus(_tabs[index].status),
            tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
        ),
        body: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('Chua co don hang nao.'));
            }
            return RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final order = items[index];
                  return _OrderCard(order: order);
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: items.length,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstItem = order.items.isEmpty ? null : order.items.first;
    final extraCount = order.items.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(order.statusText),
                  backgroundColor: order.statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: order.statusColor),
                ),
              ],
            ),
            if (firstItem != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(firstItem.productName),
                subtitle: Text(
                  extraCount > 0
                      ? 'Va $extraCount san pham khac'
                      : firstItem.variantInfo,
                ),
                trailing: Text(formatCurrency(order.totalAmount)),
              ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  child: const Text('Xem chi tiet'),
                ),
                const Spacer(),
                if (order.canCancel)
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(orderListProvider.notifier)
                          .cancelOrder(order.id);
                    },
                    child: const Text('Huy don'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTab {
  const _OrderTab(this.label, this.status);

  final String label;
  final String? status;
}

const _tabs = [
  _OrderTab('Tat ca', null),
  _OrderTab('Cho xac nhan', 'pending'),
  _OrderTab('Dang xu ly', 'processing'),
  _OrderTab('Dang giao', 'shipped'),
  _OrderTab('Da giao', 'delivered'),
  _OrderTab('Da huy', 'cancelled'),
];
