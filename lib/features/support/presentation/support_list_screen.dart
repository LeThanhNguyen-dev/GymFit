import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/support_ticket_model.dart';
import '../providers/support_provider.dart';
import 'support_detail_screen.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(userTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status filter'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In progress'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
          ),
          Expanded(
            child: tickets.when(
              data: (items) {
                final filtered = items
                    .where(
                      (ticket) => _status == null || ticket.status == _status,
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No support tickets.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _TicketTile(ticket: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load tickets: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const CreateTicketSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (ticket.orderId != null) 'Order ${ticket.orderId}',
          ticket.description,
        ].join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 6,
        children: [
          _Badge(label: ticket.statusDisplay, color: ticket.statusColor),
          _Badge(label: ticket.priorityDisplay, color: ticket.priorityColor),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SupportDetailScreen(ticketId: ticket.id),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
    );
  }
}

class CreateTicketSheet extends ConsumerStatefulWidget {
  const CreateTicketSheet({super.key});

  @override
  ConsumerState<CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'normal';

  @override
  void dispose() {
    _orderIdController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(createTicketProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create support ticket',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
              controller: _orderIdController,
              decoration: const InputDecoration(labelText: 'Order ID optional'),
            ),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 3,
              maxLines: 5,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'normal'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: submitState.isLoading ? null : _submit,
              child: submitState.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit support request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    await ref
        .read(createTicketProvider.notifier)
        .submit(
          userId: userId,
          orderId: _orderIdController.text.trim().isEmpty
              ? null
              : _orderIdController.text.trim(),
          subject: _subjectController.text,
          description: _descriptionController.text,
          priority: _priority,
        );
    if (!mounted) return;
    ref.invalidate(userTicketsProvider);
    Navigator.of(context).pop();
  }
}
