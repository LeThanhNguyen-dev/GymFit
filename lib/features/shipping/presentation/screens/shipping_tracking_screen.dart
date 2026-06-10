import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../orders/providers/order_providers.dart';
import '../../providers/shipping_providers.dart';

class ShippingTrackingScreen extends ConsumerWidget {
  const ShippingTrackingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(shippingTrackingProvider(orderId));
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Theo doi don hang')),
      body: tracking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          final latest = items.isEmpty ? null : items.first;
          final events = latest?.events.reversed.toList() ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text('#$orderId'),
                  subtitle: Text(latest?.statusDisplay ?? 'Chua co tracking'),
                  trailing: latest?.estimatedDelivery == null
                      ? null
                      : Text(
                          'Du kien\n${_date(latest!.estimatedDelivery!)}',
                          textAlign: TextAlign.end,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (events.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Don hang chua co su kien van chuyen.'),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < events.length; i++)
                          _TrackingEvent(
                            event: events[i],
                            isLatest: i == 0,
                            isLast: i == events.length - 1,
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              order.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (order) {
                  if (order == null) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thong tin don hang',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('${order.items.length} san pham'),
                          Text(
                            'Tong tien: ${formatCurrency(order.totalAmount)}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackingEvent extends StatelessWidget {
  const _TrackingEvent({
    required this.event,
    required this.isLatest,
    required this.isLast,
  });

  final Map<String, dynamic> event;
  final bool isLatest;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                isLatest ? Icons.radio_button_checked : Icons.circle,
                size: isLatest ? 22 : 12,
                color: isLatest ? Colors.green : Colors.grey,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventStatus(event['status']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (event['location'] != null)
                    Text(event['location'].toString()),
                  if (event['note'] != null) Text(event['note'].toString()),
                  if (event['created_at'] != null)
                    Text(
                      event['created_at'].toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _eventStatus(Object? value) => switch (value?.toString()) {
    'preparing' || 'pending' => 'Dang chuan bi',
    'picked_up' || 'pickedUp' => 'Da lay hang',
    'in_transit' || 'inTransit' => 'Dang van chuyen',
    'out_for_delivery' || 'outForDelivery' => 'Dang giao hang',
    'delivered' => 'Da giao',
    _ => value?.toString() ?? 'Cap nhat',
  };
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
