import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_providers.dart';

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
          title: const Text('Đơn hàng'),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) => notifier.setStatus(_tabs[index].status),
            tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
        ),
        body: orders.when(
          loading: () => const _OrdersShimmer(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.read(orderListProvider.notifier).load(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text('Chưa có đơn hàng nào.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Tiếp tục mua sắm'),
                      ),
                    ],
                  ),
                ),
              );
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
                      ? 'Và $extraCount sản phẩm khác'
                      : firstItem.variantInfo,
                ),
                trailing: Text(formatCurrency(order.totalAmount)),
              ),
            Row(
              children: [
                TextButton(
                  onPressed: () => context.push('/orders/${order.id}'),
                  child: const Text('Xem chi tiết'),
                ),
                const Spacer(),
                if (order.canCancel)
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(orderListProvider.notifier)
                          .cancelOrder(order.id);
                    },
                    child: const Text('Hủy đơn'),
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

class _OrdersShimmer extends StatefulWidget {
  const _OrdersShimmer();
  @override
  State<_OrdersShimmer> createState() => _OrdersShimmerState();
}

class _OrdersShimmerState extends State<_OrdersShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, _) => Container(
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _animation.value),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemCount: 4,
        );
      },
    );
  }
}

const _tabs = [
  _OrderTab('Tất cả', null),
  _OrderTab('Chờ xác nhận', 'pending'),
  _OrderTab('Đang xử lý', 'processing'),
  _OrderTab('Đang giao', 'shipped'),
  _OrderTab('Đã giao', 'delivered'),
  _OrderTab('Đã hủy', 'cancelled'),
];
