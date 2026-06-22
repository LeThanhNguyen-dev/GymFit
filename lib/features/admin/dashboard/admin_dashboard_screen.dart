import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'providers/dashboard_provider.dart';
import 'data/models/admin_dashboard_models.dart';
import '../../register_shop/providers/shop_registration_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  String _period = 'today';
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final pendingShopsAsync = ref.watch(shopRegistrationsByStatusProvider('pending'));
    final pendingShopsCount = pendingShopsAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan'), actions: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'today', label: Text('Hôm nay')),
            ButtonSegment(value: 'week', label: Text('Tuần')),
            ButtonSegment(value: 'month', label: Text('Tháng')),
          ],
          selected: {_period},
          onSelectionChanged: (v) => setState(() => _period = v.first),
          style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
        ),
        const SizedBox(width: 8),
      ]),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(shopRegistrationsByStatusProvider('pending'));
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi tải dữ liệu: $err')),
          data: (stats) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              children: [
                _buildStatsGrid(stats),
                const SizedBox(height: AppSpacing.lg),
                _buildPendingActions(stats, pendingShopsCount),
                const SizedBox(height: AppSpacing.lg),
                _buildCharts(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    final revenue = _period == 'today' ? stats.todayRevenue : (_period == 'week' ? stats.todayRevenue * 7.2 : stats.todayRevenue * 29.5);
    final orders = _period == 'today' ? stats.todayOrders : (_period == 'week' ? stats.todayOrders * 7 : stats.todayOrders * 30);
    
    final formattedRevenue = revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    final items = [
      _StatItem('Doanh thu', '$formattedRevenue₫', Icons.trending_up, AppColors.success),
      _StatItem('Đơn hàng mới', '$orders', Icons.receipt_long, AppColors.primary),
      _StatItem('Sản phẩm hoạt động', '${stats.activeProducts}', Icons.inventory_2, AppColors.info),
      _StatItem('Đơn chờ duyệt', '${stats.pendingOrders}', Icons.hourglass_empty, AppColors.warning),
    ];

    return Wrap(
      spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
      children: items.map((s) => SizedBox(
        width: (MediaQuery.of(context).size.width - 32 - AppSpacing.sm) / 2 - 4,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(s.icon, size: 20, color: s.color),
              const SizedBox(height: 8),
              Text(s.value, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(s.label, style: AppTextStyles.labelSmall),
            ]),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPendingActions(DashboardStats stats, int pendingShops) {
    final actions = [
      ('Đơn chờ duyệt', '${stats.pendingOrders}', Icons.hourglass_empty, AppColors.warning, RouteNames.adminOrdersPath),
      ('Shop chờ duyệt', '$pendingShops', Icons.store, AppColors.info, RouteNames.adminShopsPath),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Hành động cần xử lý', style: AppTextStyles.titleSmall),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
        children: actions.map((a) => ActionChip(
          avatar: Badge(label: Text(a.$2), child: Icon(a.$3, size: 18)),
          label: Text(a.$1, style: AppTextStyles.labelSmall),
          onPressed: () => context.go(a.$5),
        )).toList(),
      ),
    ]);
  }

  Widget _buildCharts() {
    return Column(children: [
      Card(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Doanh thu 30 ngày', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 180, child: _buildLineChart()),
        ]),
      )),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: Card(child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đơn hàng theo trạng thái', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            SizedBox(height: 160, child: _buildPieChart()),
          ]),
        ))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Card(child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top 10 Shop', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            SizedBox(height: 160, child: _buildBarChart()),
          ]),
        ))),
      ]),
      const SizedBox(height: AppSpacing.md),
      Card(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('User Growth (theo tháng)', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 160, child: _buildGrowthChart()),
        ]),
      )),
    ]);
  }

  Widget _buildLineChart() {
    return CustomPaint(painter: _MockLinePainter(), size: const Size(double.infinity, 180));
  }
  Widget _buildPieChart() {
    return CustomPaint(painter: _MockPiePainter(), size: const Size(double.infinity, 160));
  }
  Widget _buildBarChart() {
    return CustomPaint(painter: _MockBarPainter(), size: const Size(double.infinity, 160));
  }
  Widget _buildGrowthChart() {
    return CustomPaint(painter: _MockGrowthPainter(), size: const Size(double.infinity, 160));
  }
}

class _StatItem {
  _StatItem(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _MockLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final linePaint = Paint()..color = AppColors.primary..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    final values = [0.3, 0.5, 0.4, 0.6, 0.55, 0.7, 0.65, 0.8, 0.75, 0.9, 0.85, 1.0, 0.95, 0.88, 0.92, 0.78, 0.85, 0.72, 0.68, 0.82, 0.88, 0.76, 0.9, 0.95, 0.85, 0.78, 0.92, 0.88, 0.96, 1.0];
    final dx = size.width / (values.length - 1);
    path.moveTo(0, size.height * (1 - values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(i * dx, size.height * (1 - values[i]));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, linePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockPiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final data = [0.35, 0.25, 0.2, 0.15, 0.05];
    final colors = [AppColors.primary, AppColors.success, AppColors.warning, AppColors.info, AppColors.error];
    var startAngle = -1.5708;
    for (var i = 0; i < data.length; i++) {
      final sweep = data[i] * 6.28319;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, Paint()..color = colors[i]);
      startAngle += sweep;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 12;
    final values = [0.9, 0.8, 0.7, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3];
    for (var i = 0; i < values.length; i++) {
      final h = size.height * values[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * (barWidth + 2) + 4, size.height - h, barWidth - 2, h), const Radius.circular(3)),
        Paint()..color = AppColors.primary.withValues(alpha: 0.6 + 0.4 * (1 - i / values.length)),
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockGrowthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.info.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final linePaint = Paint()..color = AppColors.info..strokeWidth = 2;
    final dotPaint = Paint()..color = AppColors.info..style = PaintingStyle.fill;
    final values = [0.2, 0.25, 0.3, 0.4, 0.38, 0.45, 0.55, 0.6, 0.58, 0.65, 0.7, 0.8];
    final dx = size.width / (values.length - 1);
    final path = Path();
    path.moveTo(0, size.height * (1 - values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(i * dx, size.height * (1 - values[i]));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, linePaint..style = PaintingStyle.stroke);
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(i * dx, size.height * (1 - values[i])), 3, dotPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
