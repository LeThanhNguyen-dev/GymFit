import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/support_provider.dart';

class SupportDetailScreen extends ConsumerWidget {
  const SupportDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket detail')),
      body: ticket.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Ticket not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.subject,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(label: Text(item.statusDisplay)),
                ],
              ),
              Text('Priority: ${item.priorityDisplay}'),
              if (item.orderId != null) Text('Order: ${item.orderId}'),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(item.description),
              const SizedBox(height: 20),
              Text(
                'Admin reply',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (item.adminReply == null || item.adminReply!.isEmpty)
                const Text('Waiting for response...')
              else ...[
                Text(item.adminReply!),
                if (item.repliedAt != null)
                  Text('Replied at ${item.repliedAt}'),
              ],
              const SizedBox(height: 20),
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              _TimelineRow(label: 'Created', active: true),
              _TimelineRow(label: 'In progress', active: item.status != 'open'),
              _TimelineRow(
                label: 'Resolved',
                active: item.status == 'resolved' || item.status == 'closed',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load ticket: $error')),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? Colors.green : Colors.grey,
      ),
      title: Text(label),
    );
  }
}
