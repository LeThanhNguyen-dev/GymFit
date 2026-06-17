import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodToggle(),
            const SizedBox(height: AppSpacing.md),
            _buildStatsGrid(),
            const SizedBox(height: AppSpacing.lg),
            _buildRevenueChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildTopProducts(),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickActions(),
          ],
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

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (_, constraints) => Wrap(
        spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
        children: [
          _StatCard(label: 'Doanh thu', value: '12.450.000₫', icon: Icons.trending_up, color: AppColors.success),
          _StatCard(label: 'Đơn hàng', value: '28 (3 chờ)', icon: Icons.receipt_long, color: AppColors.primary),
          _StatCard(label: 'Lượt xem', value: '1.240', icon: Icons.visibility, color: AppColors.info),
          _StatCard(label: 'Tồn kho', value: '156 (8 hết)', icon: Icons.inventory_2, color: AppColors.warning),
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
            Text('Doanh thu 7 ngày', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: 'T23456H'.split('').asMap().entries.map((e) {
                  final h = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.5][e.key];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 160 * h,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

  Widget _buildTopProducts() {
    final products = ['Gym Bag Pro', 'Towel XL', 'Water Bottle', 'Wrist Wraps', 'Jump Rope'];
    final sales = [45, 38, 30, 22, 18];
    final maxSale = sales[0];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 sản phẩm bán chạy', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 120, child: Text(products[i], style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sales[i] / maxSale,
                        minHeight: 12,
                        backgroundColor: AppColors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 40, child: Text('${sales[i]}', style: AppTextStyles.labelSmall, textAlign: TextAlign.right)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hành động nhanh', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.pending_actions, label: 'Đơn chờ xử lý', badge: '3',
          color: AppColors.warning, onTap: () => context.go(RouteNames.storeOrdersPath),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.inventory, label: 'Sản phẩm hết hàng', badge: '8',
          color: AppColors.error, onTap: () => context.go(RouteNames.storeProductsPath),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionCard(
          icon: Icons.rate_review, label: 'Đánh giá mới', badge: '2',
          color: AppColors.info, onTap: () => context.go(RouteNames.storeSettingsPath),
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
              Text(value, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
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
