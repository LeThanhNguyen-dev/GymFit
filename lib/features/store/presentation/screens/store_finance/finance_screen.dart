import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../register_shop/providers/shop_registration_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _bankNameCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bankNameCtrl.dispose();
    _accCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBankAccount(dynamic reg) async {
    try {
      final metadata = {
        ...reg.metadata,
        'bank': {
          'bank_name': _bankNameCtrl.text.trim(),
          'account_number': _accCtrl.text.trim(),
          'account_holder': _holderCtrl.text.trim(),
        }
      };
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('shop_registrations').update({'metadata': metadata}).eq('id', reg.id);
      ref.invalidate(myShopRegistrationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thông tin ngân hàng thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regAsync = ref.watch(myShopRegistrationProvider);
    final supabase = ref.watch(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài chính'), elevation: 0),
      body: regAsync.when(
        data: (reg) {
          if (reg == null) {
            return const Center(child: Text('Đang tải thông tin Shop...'));
          }

          final meta = reg.metadata;
          final bankDetails = meta['bank'] != null ? Map<String, dynamic>.from(meta['bank']) : <String, dynamic>{};

          return FutureBuilder<Map<String, dynamic>>(
            future: userId == null
                ? Future.value({'revenue': 0.0, 'withdrawn': 0.0, 'balance': 0.0, 'completed_orders_count': 0})
                : supabase.rpc('get_store_stats', params: {'p_seller_id': userId}).then((res) => Map<String, dynamic>.from(res ?? {})),
            builder: (ctx, snapshot) {
              final stats = snapshot.data ?? {'revenue': 0.0, 'withdrawn': 0.0, 'balance': 0.0, 'order_count': 0};
              final revenue = double.tryParse(stats['revenue']?.toString() ?? '0') ?? 0.0;
              final withdrawn = double.tryParse(stats['withdrawn']?.toString() ?? '0') ?? 0.0;
              final balance = double.tryParse(stats['balance']?.toString() ?? '0') ?? 0.0;

              final fmtRevenue = revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              final fmtWithdrawn = withdrawn.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              final fmtBalance = balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

              return Column(
                children: [
                  _buildBalanceOverview(fmtRevenue, fmtWithdrawn, fmtBalance),
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabs: 'Tổng quan|Lịch sử|Ngân hàng'.split('|').map((t) => Tab(text: t)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabCtrl, children: [
                      _buildOverview(fmtRevenue, fmtWithdrawn, fmtBalance, stats['order_count']?.toString() ?? '0'),
                      _buildWithdraw(reg, balance, supabase),
                      _buildHistory(userId, supabase),
                      _buildBankAccounts(reg, bankDetails),
                    ]),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildBalanceOverview(String fmtRevenue, String fmtWithdrawn, String fmtBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      color: AppColors.primary,
      child: Column(
        children: [
          Text('Tổng doanh thu', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('$fmtRevenue₫', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _balanceItem('Khả dụng', '$fmtBalance₫'),
            _balanceItem('Đã rút', '$fmtWithdrawn₫'),
          ]),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _buildOverview(String fmtRevenue, String fmtWithdrawn, String fmtBalance, String totalOrders) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng quan thu nhập', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _statRow('Doanh thu tích luỹ', '$fmtRevenue₫'),
            _statRow('Đã rút / Đang xử lý', '$fmtWithdrawn₫'),
            _statRow('Số dư khả dụng', '$fmtBalance₫'),
            const Divider(height: 24),
            _statRow('Tổng đơn hàng thành công', totalOrders),
          ]),
        ),
      ),
    ]);
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildWithdraw(dynamic reg, double maxAmount, dynamic supabase) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Text('Số dư khả dụng để rút: ${maxAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫', style: AppTextStyles.bodyMedium),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _amountCtrl,
        decoration: const InputDecoration(labelText: 'Số tiền rút (₫)', border: OutlineInputBorder(), prefixText: '₫ '),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.md),
      if (_bankDetails['account_number']?.isNotEmpty == true)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tài khoản nhận', style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('${_bankDetails['bank_name']} • ${_bankDetails['account_number']}', style: AppTextStyles.bodyLarge),
              Text(_bankDetails['account_holder'] ?? '', style: AppTextStyles.bodyMedium),
            ],
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Vui lòng qua tab "Ngân hàng" để thiết lập thông tin tài khoản trước khi rút tiền.', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      FilledButton.icon(
        onPressed: _isSubmitting || _bankDetails['account_number']?.isEmpty == true
            ? null
            : () async {
                final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                if (amount <= 0 || amount > maxAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền rút không hợp lệ!')));
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  await supabase.rpc('request_payout', params: {
                    'p_amount': amount,
                    'p_bank_name': _bankDetails['bank_name'],
                    'p_account_number': _bankDetails['account_number'],
                    'p_account_holder': _bankDetails['account_holder'],
                  });
                  if (mounted) {
                    _amountCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu rút tiền thành công!')));
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
        icon: const Icon(Icons.send),
        label: const Text('Gửi yêu cầu rút tiền'),
      ),
    ]);
  }

  Widget _buildHistory(String? userId, dynamic supabase) {
    return FutureBuilder<List<dynamic>>(
      future: userId == null
          ? Future.value([])
               : supabase
               .from('payout_requests')
               .select('*')
               .eq('seller_id', userId)
              .order('created_at', ascending: false),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử rút tiền.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = items[i];
            final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
            final date = DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16);
            final status = item['status']?.toString() ?? 'pending';

            Color statusColor;
            String statusText;
            switch (status) {
              case 'approved':
              case 'completed':
                statusColor = AppColors.success;
                statusText = 'Thành công';
                break;
              case 'rejected':
                statusColor = AppColors.error;
                statusText = 'Bị từ chối';
                break;
              default:
                statusColor = AppColors.warning;
                statusText = 'Đang xử lý';
            }

            return ListTile(
              title: Text('Rút tiền về ${item['bank_name']}', style: AppTextStyles.bodyMedium),
              subtitle: Text(date, style: AppTextStyles.labelSmall),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('-$formattedAmount₫', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(statusText, style: AppTextStyles.labelSmall.copyWith(color: statusColor)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBankAccounts(dynamic reg, Map<String, dynamic> bankDetails) {
    _bankNameCtrl.text = bankDetails['bank_name'] ?? '';
    _accCtrl.text = bankDetails['account_number'] ?? '';
    _holderCtrl.text = bankDetails['account_holder'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('Thông tin tài khoản ngân hàng nhận tiền', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bankNameCtrl,
          decoration: const InputDecoration(labelText: 'Tên ngân hàng (VD: Vietcombank)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _accCtrl,
          decoration: const InputDecoration(labelText: 'Số tài khoản', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _holderCtrl,
          decoration: const InputDecoration(labelText: 'Tên chủ tài khoản', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _saveBankAccount(reg),
          child: const Text('Lưu thông tin ngân hàng'),
        ),
      ],
    );
  }
}
