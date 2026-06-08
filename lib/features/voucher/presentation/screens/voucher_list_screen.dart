import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/voucher_model.dart';
import '../../providers/voucher_provider.dart';

class VoucherListScreen extends ConsumerStatefulWidget {
  const VoucherListScreen({super.key, required this.orderAmount});

  final double orderAmount;

  @override
  ConsumerState<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends ConsumerState<VoucherListScreen> {
  final _codeController = TextEditingController();
  String? _message;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    ref.read(voucherOrderAmountProvider.notifier).setAmount(widget.orderAmount);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vouchersState = ref.watch(availableVouchersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mã giảm giá')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(availableVouchersProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nhập mã voucher',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isApplying ? null : () => _applyCode(context),
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!),
            ],
            const SizedBox(height: 16),
            vouchersState.when(
              loading: () => const _VoucherLoading(),
              error: (error, _) => Text(error.toString()),
              data: (vouchers) => Column(
                children: vouchers
                    .map(
                      (voucher) => _VoucherCard(
                        voucher: voucher,
                        orderAmount: widget.orderAmount,
                        onApply: () => _applyVoucher(context, voucher),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyCode(BuildContext context) async {
    setState(() {
      _isApplying = true;
      _message = null;
    });

    try {
      final result = await ref
          .read(voucherRepositoryProvider)
          .validateVoucher(_codeController.text, widget.orderAmount);
      _setApplied(result.voucher);
      if (context.mounted) context.pop(result.voucher);
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _applyVoucher(BuildContext context, VoucherModel voucher) {
    _setApplied(voucher);
    context.pop(voucher);
  }

  void _setApplied(VoucherModel voucher) {
    ref.read(voucherOrderAmountProvider.notifier).setAmount(widget.orderAmount);
    ref.read(appliedVoucherProvider.notifier).setVoucher(voucher);
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.orderAmount,
    required this.onApply,
  });

  final VoucherModel voucher;
  final double orderAmount;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final canApply = voucher.canUse && orderAmount >= voucher.minOrderAmount;
    final discount = voucher.calculateDiscount(orderAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(voucher.discountDisplay)),
        title: Text(voucher.code),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (voucher.description != null) Text(voucher.description!),
            Text('Đơn tối thiểu ${formatCurrency(voucher.minOrderAmount)}'),
            Text(
              'HSD: ${voucher.endDate.day.toString().padLeft(2, '0')}/'
              '${voucher.endDate.month.toString().padLeft(2, '0')}/'
              '${voucher.endDate.year}',
            ),
            if (!canApply)
              Text(
                'Không đủ điều kiện áp dụng',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Text('Giảm ${formatCurrency(discount)}'),
          ],
        ),
        trailing: FilledButton(
          onPressed: canApply ? onApply : null,
          child: const Text('Áp dụng'),
        ),
      ),
    );
  }
}

class _VoucherLoading extends StatelessWidget {
  const _VoucherLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 112,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
