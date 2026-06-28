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
    final revenueAsync = ref.watch(_adminRevenueProvider);
    final paymentsAsync = ref.watch(_adminRecentPaymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tài chính')),
      body: ListView(
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
      ),
    );
  }
}
