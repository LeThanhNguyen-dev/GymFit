import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../../orders/data/models/order_model.dart';
import '../dashboard/providers/dashboard_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(adminOrderRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage orders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...OrderStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status.name,
                    child: Text(status.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: repository.getAdminOrders(status: _status),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data!;
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders.'));
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      title: Text(order.orderNumber),
                      subtitle: Text(
                        '${order.shippingFullName} - ${order.status.name}',
                      ),
                      trailing: Text('${order.totalAmount.round()}d'),
                      onTap: () => _showStatusDialog(order),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(OrderModel order) async {
    var status = order.status;
    final note = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(order.orderNumber),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<OrderStatus>(
                initialValue: status,
                items: OrderStatus.values
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setLocalState(() => status = value ?? status),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final userId = ref
                    .read(supabaseClientProvider)
                    .auth
                    .currentUser
                    ?.id;
                await ref
                    .read(adminOrderRepositoryProvider)
                    .updateOrderStatus(
                      order.id,
                      status,
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                      changedBy: userId,
                    );
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
