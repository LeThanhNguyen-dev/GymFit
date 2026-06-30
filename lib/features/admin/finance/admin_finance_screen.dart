import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';

final _adminRevenueProvider = FutureProvider.autoDispose<double>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('payments')
      .select('amount')
      .eq('status', 'paid');
  double total = 0;
  for (final r in rows) {
    total += (r['amount'] as num?)?.toDouble() ?? 0;
  }
  return total;
});

final _adminRecentPaymentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('payments')
      .select('id, amount, method, status, created_at, order_id')
      .order('created_at', ascending: false)
      .limit(50);
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tài chính'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Doanh thu'),
              Tab(text: 'Rút tiền'),
              Tab(text: 'Cấu hình phí'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRevenueTab(context, ref),
            _buildWithdrawalsTab(ref),
            _buildFeeConfigTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(_adminRevenueProvider);
    final paymentsAsync = ref.watch(_adminRecentPaymentsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: [
              Text('Tổng doanh thu sàn', style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              revenueAsync.when(
                data: (revenue) => Text(
                  formatCurrency(revenue),
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                ),
                loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Text('0₫', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Giao dịch gần đây', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Card(child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Chưa có giao dịch nào.')),
              ));
            }
            return Card(
              child: Column(
                children: payments.map((p) => ListTile(
                  dense: true,
                  title: Text('${p['method']} - ${p['status']}', style: AppTextStyles.bodySmall),
                  subtitle: Text(p['created_at']?.toString().substring(0, 16) ?? '', style: AppTextStyles.labelSmall),
                  trailing: Text(formatCurrency((p['amount'] as num?)?.toDouble() ?? 0), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Card(child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Lỗi tải dữ liệu: $e')),
          )),
        ),
      ],
    );
  }

  Widget _buildWithdrawalsTab(WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);
    return FutureBuilder<List<dynamic>>(
      future: supabase.rpc('get_admin_payout_requests').then((res) => List<dynamic>.from(res ?? [])),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final allItems = snapshot.data ?? [];
        final pending = allItems.where((i) => i['status'] == 'pending').toList();
        final approved = allItems.where((i) => i['status'] == 'approved' || i['status'] == 'completed').toList();
        final rejected = allItems.where((i) => i['status'] == 'rejected').toList();

        return DefaultTabController(
          length: 3,
          child: Column(children: [
            TabBar(tabs: 'Chờ duyệt|Đã duyệt|Từ chối'.split('|').map((t) => Tab(text: t)).toList()),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPayoutList(pending, supabase, ref),
                  _buildPayoutList(approved, supabase, ref),
                  _buildPayoutList(rejected, supabase, ref),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildPayoutList(List<dynamic> items, dynamic supabase, WidgetRef ref) {
    if (items.isEmpty) return const Center(child: Text('Không có yêu cầu nào.'));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final item = items[i];
        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final fmtAmount = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        final date = DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16);

        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, child: const Icon(Icons.payments, color: Colors.grey)),
            title: Text('${item['seller_name']} - $fmtAmount₫', style: AppTextStyles.bodyMedium),
            subtitle: Text('${item['bank_name']} - $date', style: AppTextStyles.labelSmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWithdrawalDetail(context, item, supabase, ref),
          ),
        );
      },
    );
  }

  void _showWithdrawalDetail(BuildContext context, Map<String, dynamic> wd, dynamic supabase, WidgetRef ref) {
    final amount = double.tryParse(wd['amount']?.toString() ?? '0') ?? 0.0;
    final fmtAmount = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final isPending = wd['status'] == 'pending';

    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Rút tiền - ${wd['seller_name']}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Số tiền: $fmtAmount₫', style: AppTextStyles.bodyMedium),
        Text('Ngân hàng: ${wd['bank_name']}', style: AppTextStyles.bodySmall),
        Text('Số TK: ${wd['account_number']}', style: AppTextStyles.bodySmall),
        Text('Chủ TK: ${wd['account_holder']}', style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Text('Trạng thái: ${wd['status']}', style: AppTextStyles.bodySmall),
        if (wd['rejection_reason'] != null) ...[
          const Divider(),
          Text('Lý do từ chối: ${wd['rejection_reason']}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ]
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        if (isPending) ...[
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.rpc('admin_update_payout_status', params: {
                  'p_payout_id': wd['id'],
                  'p_status': 'rejected',
                  'p_reason': 'Thông tin không hợp lệ',
                });
                ref.invalidate(_adminRecentPaymentsProvider);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.rpc('admin_update_payout_status', params: {
                  'p_payout_id': wd['id'],
                  'p_status': 'completed',
                });
                ref.invalidate(_adminRecentPaymentsProvider);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Đã chuyển khoản'),
          ),
        ]
      ],
    ));
  }

  Widget _buildFeeConfigTab() {
    final feeCtrl = TextEditingController(text: '2.5');
    final catFees = ['Thể thao: 2%', 'Dinh dưỡng: 3%', 'Phụ kiện: 2.5%'];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phí sàn mặc định (%)', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: '%')),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () {}, child: const Text('Lưu'))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phí theo danh mục', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              ...catFees.map((f) => ListTile(
                title: Text(f, style: AppTextStyles.bodySmall),
                trailing: IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                dense: true,
              )),
            ]),
          ),
        ),
      ],
    );
  }
}
