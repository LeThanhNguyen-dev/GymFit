import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voucher/data/models/voucher_model.dart';
import '../../voucher/providers/voucher_provider.dart';

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(voucherRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage vouchers')),
      body: FutureBuilder<List<VoucherModel>>(
        future: repository.getAdminVouchers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final vouchers = snapshot.data!;
          if (vouchers.isEmpty) {
            return const Center(child: Text('No vouchers.'));
          }
          return ListView.separated(
            itemCount: vouchers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return ListTile(
                title: Text(voucher.code),
                subtitle: Text(
                  '${voucher.discountDisplay} - used ${voucher.usedCount}',
                ),
                trailing: Switch(
                  value: voucher.isActive,
                  onChanged: (value) async {
                    await repository.saveVoucher({
                      'is_active': value,
                    }, id: voucher.id);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                onTap: () => _showVoucherDialog(voucher),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVoucherDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showVoucherDialog(VoucherModel? voucher) async {
    final code = TextEditingController(text: voucher?.code);
    final description = TextEditingController(text: voucher?.description);
    final value = TextEditingController(
      text: voucher?.discountValue.toString() ?? '0',
    );
    final minOrder = TextEditingController(
      text: voucher?.minOrderAmount.toString() ?? '0',
    );
    final usageLimit = TextEditingController(
      text: voucher?.usageLimit?.toString(),
    );
    var discountType = voucher?.discountType ?? 'percentage';
    var active = voucher?.isActive ?? true;
    var startDate = voucher?.startDate ?? DateTime.now();
    var endDate =
        voucher?.endDate ?? DateTime.now().add(const Duration(days: 30));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(voucher == null ? 'Add voucher' : 'Edit voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed_amount',
                      child: Text('Fixed amount'),
                    ),
                  ],
                  onChanged: (next) =>
                      setLocalState(() => discountType = next ?? discountType),
                ),
                TextField(
                  controller: value,
                  decoration: const InputDecoration(
                    labelText: 'Discount value',
                  ),
                ),
                TextField(
                  controller: minOrder,
                  decoration: const InputDecoration(labelText: 'Min order'),
                ),
                TextField(
                  controller: usageLimit,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit optional',
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (next) => setLocalState(() => active = next),
                  title: const Text('Active'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: startDate,
                    );
                    if (picked != null) {
                      setLocalState(() => startDate = picked);
                    }
                  },
                  child: Text(
                    'Start: ${startDate.toIso8601String().split('T').first}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: endDate,
                    );
                    if (picked != null) {
                      setLocalState(() => endDate = picked);
                    }
                  },
                  child: Text(
                    'End: ${endDate.toIso8601String().split('T').first}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(voucherRepositoryProvider).saveVoucher({
                  'code': code.text.trim().toUpperCase(),
                  'description': description.text.trim(),
                  'discount_type': discountType,
                  'discount_value': double.tryParse(value.text.trim()) ?? 0,
                  'min_order_amount':
                      double.tryParse(minOrder.text.trim()) ?? 0,
                  'usage_limit': int.tryParse(usageLimit.text.trim()),
                  'is_active': active,
                  'start_date': startDate.toIso8601String(),
                  'end_date': endDate.toIso8601String(),
                }, id: voucher?.id);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
