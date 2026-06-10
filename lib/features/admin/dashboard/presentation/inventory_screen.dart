import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../providers/dashboard_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = ref.watch(lowStockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: lowStock.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No low-stock variants.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = item.stock <= 5
                  ? Colors.red
                  : Colors.amber.shade800;
              return ListTile(
                leading: Icon(Icons.warehouse, color: color),
                title: Text(item.productName),
                subtitle: Text(item.variantName ?? item.sku ?? item.variantId),
                trailing: Text(
                  item.stock.toString(),
                  style: TextStyle(color: color),
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => _StockDialog(variantId: item.variantId),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load inventory: $error')),
      ),
    );
  }
}

class _StockDialog extends ConsumerStatefulWidget {
  const _StockDialog({required this.variantId});

  final String variantId;

  @override
  ConsumerState<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends ConsumerState<_StockDialog> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restock variant'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity == 0) return;
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    await ref
        .read(inventoryRepositoryProvider)
        .createInventoryLog(
          variantId: widget.variantId,
          changeType: 'restock',
          quantityChange: quantity,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdBy: userId,
        );
    if (!mounted) return;
    ref.invalidate(lowStockProvider);
    Navigator.of(context).pop();
  }
}
