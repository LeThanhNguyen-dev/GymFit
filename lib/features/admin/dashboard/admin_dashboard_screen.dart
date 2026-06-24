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
                _buildCharts(stats),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    final revenue = _period == 'today'
        ? stats.todayRevenue
        : (_period == 'week' ? stats.weekRevenue : stats.monthRevenue);
    final orders = _period == 'today'
        ? stats.todayOrders
        : (_period == 'week' ? stats.weekOrders : stats.monthOrders);
    
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

  Widget _buildCharts(DashboardStats stats) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    return Column(children: [
      Card(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Doanh thu 30 ngày', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 180, child: _buildLineChart(stats.dailyRevenue30Days)),
        ]),
      )),
      const SizedBox(height: AppSpacing.md),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Card(child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đơn hàng theo trạng thái', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            SizedBox(height: 130, child: _buildPieChart(stats.ordersByStatus, cardColor)),
            const SizedBox(height: 8),
            _buildPieChartLegend(stats.ordersByStatus),
          ]),
        ))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Card(child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top 10 Shop', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            SizedBox(height: 130, child: _buildBarChart(stats.topShops)),
            const SizedBox(height: 8),
            _buildBarChartLegend(stats.topShops),
          ]),
        ))),
      ]),
      const SizedBox(height: AppSpacing.md),
      Card(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('User Growth (theo tháng)', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 160, child: _buildGrowthChart(stats.monthlyUserGrowth)),
        ]),
      )),
    ]);
  }

  Widget _buildLineChart(List<double> dailyRevenue) {
    return CustomPaint(
      painter: LineChartPainter(dailyRevenue),
      size: const Size(double.infinity, 180),
    );
  }

  Widget _buildPieChart(Map<String, int> ordersByStatus, Color cardColor) {
    return CustomPaint(
      painter: PieChartPainter(ordersByStatus, backgroundColor: cardColor),
      size: const Size(double.infinity, 130),
    );
  }

  Widget _buildPieChartLegend(Map<String, int> statusCounts) {
    final Map<String, (String, Color)> statusMapping = {
      'pending': ('Chờ xác nhận', AppColors.warning),
      'confirmed': ('Đã xác nhận', AppColors.primary),
      'shipped': ('Đang giao', Colors.indigo),
      'delivered': ('Đã giao', AppColors.success),
      'cancelled': ('Đã hủy', AppColors.error),
    };

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: statusCounts.entries.map((entry) {
        final config = statusMapping[entry.key] ?? (entry.key, Colors.grey);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: config.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${config.$1} (${entry.value})',
              style: const TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(List<ShopRevenue> topShops) {
    return CustomPaint(
      painter: BarChartPainter(topShops),
      size: const Size(double.infinity, 130),
    );
  }

  Widget _buildBarChartLegend(List<ShopRevenue> topShops) {
    if (topShops.isEmpty) return const SizedBox.shrink();
    return Column(
      children: topShops.take(3).map((shop) {
        final formattedRev = shop.revenue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
        return Row(
          children: [
            Expanded(
              child: Text(
                shop.shopName,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${formattedRev}đ',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGrowthChart(List<MonthlyGrowth> growth) {
    return CustomPaint(
      painter: GrowthChartPainter(growth),
      size: const Size(double.infinity, 160),
    );
  }
}

class _StatItem {
  _StatItem(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class LineChartPainter extends CustomPainter {
  LineChartPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      _paintNoData(canvas, size);
      return;
    }
    
    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final limit = maxVal == 0 ? 10000.0 : maxVal;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final dx = size.width / (values.length - 1);
    
    path.moveTo(0, size.height * (1 - values[0] / limit) * 0.85 + size.height * 0.1);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(i * dx, size.height * (1 - values[i] / limit) * 0.85 + size.height * 0.1);
    }
    
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);

    // Draw max value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Max: ${maxVal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}đ',
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));
  }

  void _paintNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có dữ liệu doanh thu',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  PieChartPainter(this.statusCounts, {required this.backgroundColor});
  final Map<String, int> statusCounts;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = statusCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      _paintNoData(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    
    final statuses = statusCounts.keys.toList();
    final colors = [
      AppColors.warning, 
      AppColors.primary, 
      Colors.indigo,
      AppColors.success, 
      AppColors.error,
      Colors.teal,
      Colors.pink,
    ];
    
    var startAngle = -1.5708;
    for (var i = 0; i < statuses.length; i++) {
      final sweep = (statusCounts[statuses[i]]! / total) * 6.28319;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      startAngle += sweep;
    }

    // Donut inner hole
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = backgroundColor,
    );
  }

  void _paintNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có đơn hàng',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  BarChartPainter(this.shops);
  final List<ShopRevenue> shops;

  @override
  void paint(Canvas canvas, Size size) {
    if (shops.isEmpty) {
      _paintNoData(canvas, size);
      return;
    }

    final maxVal = shops.fold<double>(0.0, (m, shop) => shop.revenue > m ? shop.revenue : m);
    final limit = maxVal == 0 ? 10000.0 : maxVal;

    final barWidth = size.width / 12;
    for (var i = 0; i < shops.length; i++) {
      final h = size.height * (shops[i].revenue / limit) * 0.8;
      final x = i * (barWidth + 2) + 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth - 1, h),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.primary.withOpacity(0.6 + 0.4 * (1 - i / shops.length)),
      );
    }
  }

  void _paintNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có doanh thu',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GrowthChartPainter extends CustomPainter {
  GrowthChartPainter(this.growth);
  final List<MonthlyGrowth> growth;

  @override
  void paint(Canvas canvas, Size size) {
    if (growth.isEmpty) {
      _paintNoData(canvas, size);
      return;
    }

    final maxVal = growth.fold<int>(0, (m, g) => g.count > m ? g.count : m);
    final limit = maxVal == 0 ? 10.0 : maxVal.toDouble();

    final paint = Paint()
      ..color = AppColors.info.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.info
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = AppColors.info
      ..style = PaintingStyle.fill;

    final dx = size.width / (growth.length - 1);
    final path = Path();
    
    path.moveTo(0, size.height * (1 - growth[0].count / limit) * 0.85 + size.height * 0.1);
    for (var i = 1; i < growth.length; i++) {
      path.lineTo(i * dx, size.height * (1 - growth[i].count / limit) * 0.85 + size.height * 0.1);
    }
    
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);
    
    for (var i = 0; i < growth.length; i++) {
      canvas.drawCircle(
        Offset(i * dx, size.height * (1 - growth[i].count / limit) * 0.85 + size.height * 0.1),
        3,
        dotPaint,
      );
    }

    // Draw labels for the first, middle, and last month
    _drawMonthLabel(canvas, growth[0].month, 0, size.height - 4, size);
    _drawMonthLabel(canvas, growth[growth.length ~/ 2].month, (growth.length ~/ 2) * dx, size.height - 4, size);
    _drawMonthLabel(canvas, growth[growth.length - 1].month, size.width, size.height - 4, size);
  }

  void _drawMonthLabel(Canvas canvas, String label, double x, double y, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double adjustedX = x - textPainter.width / 2;
    if (adjustedX < 0) adjustedX = 0;
    if (adjustedX + textPainter.width > size.width) adjustedX = size.width - textPainter.width;

    textPainter.paint(canvas, Offset(adjustedX, y - 10));
  }

  void _paintNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có thông tin tăng trưởng',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
