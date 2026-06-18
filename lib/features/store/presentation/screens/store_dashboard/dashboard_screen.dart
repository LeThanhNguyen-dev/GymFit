import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _periodIndex = 0;
  final periods = ['Hôm nay', 'Tuần này', 'Tháng này'];

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan'), elevation: 0),
      body: userId == null
          ? const Center(child: Text('Đang tải thông tin...'))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: FutureBuilder<Map<String, dynamic>>(
                future: supabase.rpc('get_store_stats', params: {'p_seller_id': userId}).then((res) => Map<String, dynamic>.from(res ?? {})),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data ?? {};
                  final revenue = double.tryParse(stats['revenue']?.toString() ?? '0') ?? 0.0;
                  final formattedRevenue = revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodToggle(),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatsGrid(stats, formattedRevenue),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRevenueChart(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTopProducts(userId, supabase),
                        const SizedBox(height: AppSpacing.lg),
                        _buildQuickActions(stats),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPeriodToggle() {
    return SegmentedButton<int>(
      segments: List.generate(3, (i) => ButtonSegment(value: i, label: Text(periods[i], style: AppTextStyles.labelMedium))),
      selected: {_periodIndex},
      onSelectionChanged: (v) => setState(() => _periodIndex = v.first),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, String revenueText) {
    return LayoutBuilder(
      builder: (_, constraints) => Wrap(
        spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
        children: [
          _StatCard(label: 'Doanh thu', value: '$revenueText₫', icon: Icons.trending_up, color: AppColors.success),
          _StatCard(label: 'Đơn hàng', value: '${stats['order_count'] ?? 0}', icon: Icons.receipt_long, color: AppColors.primary),
          _StatCard(label: 'Sản phẩm bán', value: '${stats['product_count'] ?? 0}', icon: Icons.inventory_2, color: AppColors.info),
          _StatCard(label: 'Hết hàng', value: '${stats['out_of_stock_count'] ?? 0}', icon: Icons.warning_amber_rounded, color: AppColors.warning),
        ].map((s) => SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: s)).toList(),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doanh thu 7 ngày qua', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: 'T23456H'.split('').asMap().entries.map((e) {
                  final h = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.5][e.key];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 140 * h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(e.value, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(String userId, dynamic supabase) {
    return FutureBuilder<List<dynamic>>(
      future: supabase
          .from('products')
          .select('name, total_sold')
          .eq('seller_id', userId)
          .order('total_sold', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có số liệu sản phẩm bán chạy.')));
        }

        final maxSold = products.isNotEmpty ? (products[0]['total_sold'] as int? ?? 1) : 1;
        final maxSoldValue = maxSold == 0 ? 1 : maxSold;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sản phẩm bán chạy nhất', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(products.length, (i) {
                  final name = products[i]['name']?.toString() ?? '';
                  final sold = products[i]['total_sold'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(name, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sold / maxSoldValue,
                              minHeight: 12,
                              backgroundColor: AppColors.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$sold', style: AppTextStyles.labelSmall),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hành động nhanh', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.pending_actions, label: 'Đơn chờ xử lý', badge: null,
          color: AppColors.warning, onTap: () => context.go(RouteNames.storeOrdersPath),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.inventory, label: 'Quản lý sản phẩm', badge: '${stats['product_count'] ?? 0}',
          color: AppColors.primary, onTap: () => context.go(RouteNames.storeProductsPath),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.account_balance_wallet, label: 'Tài chính & Thu nhập', badge: null,
          color: AppColors.success, onTap: () => context.go(RouteNames.storeFinancePath),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(value, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, this.badge, required this.color, required this.onTap});
  final IconData icon; final String label; final String? badge; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
        title: Text(label, style: AppTextStyles.bodyMedium),
        trailing: badge != null ? Chip(label: Text(badge!, style: const TextStyle(fontSize: 11)), backgroundColor: color.withValues(alpha: 0.15)) : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
