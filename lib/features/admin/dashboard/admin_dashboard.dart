import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../orders/data/models/order_model.dart';
import '../../auth/providers/auth_providers.dart';
import 'data/models/admin_dashboard_models.dart';
import 'providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final revenue = ref.watch(revenueByCategoryProvider);
    final lowStock = ref.watch(lowStockProvider);
    final recentOrders = ref.watch(recentOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Về trang người dùng',
            onPressed: () => context.go(RouteNames.homePath),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(revenueByCategoryProvider);
          ref.invalidate(lowStockProvider);
          ref.invalidate(recentOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            stats.when(
              data: _StatsGrid.new,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: AppLoading(message: 'Đang tải thống kê...'),
              ),
              error: (error, _) => AppErrorWidget(
                message: 'Không thể tải thống kê: $error',
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Revenue by category'),
            revenue.when(
              data: (items) => _RevenueChart(items: items),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoading(message: 'Đang tải...'),
              ),
              error: (error, _) => AppErrorWidget(
                message: 'Không thể tải doanh thu: $error',
                onRetry: () => ref.invalidate(revenueByCategoryProvider),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Low stock warning'),
            lowStock.when(
              data: (items) => _LowStockList(items: items),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoading(message: 'Đang tải...'),
              ),
              error: (error, _) => AppErrorWidget(
                message: 'Không thể tải tồn kho: $error',
                onRetry: () => ref.invalidate(lowStockProvider),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Recent orders'),
            recentOrders.when(
              data: (orders) => _RecentOrders(orders: orders),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoading(message: 'Đang tải...'),
              ),
              error: (error, _) => AppErrorWidget(
                message: 'Không thể tải đơn hàng: $error',
                onRetry: () => ref.invalidate(recentOrdersProvider),
              ),
            ),
            const SizedBox(height: 24),
            const _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(this.stats);

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          label: 'Orders today',
          value: stats.todayOrders.toString(),
          icon: Icons.inventory_2,
        ),
        _StatCard(
          label: 'Revenue today',
          value: _money(stats.todayRevenue),
          icon: Icons.payments,
        ),
        _StatCard(
          label: 'Pending orders',
          value: stats.pendingOrders.toString(),
          icon: Icons.hourglass_top,
        ),
        _StatCard(
          label: 'Active products',
          value: stats.activeProducts.toString(),
          icon: Icons.bar_chart,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.items});

  final List<RevenueByCategoryModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.bar_chart,
        message: 'Chưa có dữ liệu doanh thu',
      );
    }
    final maxRevenue = items
        .map((item) => item.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: items.take(6).map((item) {
        final factor = maxRevenue == 0 ? 0.0 : item.revenue / maxRevenue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  item.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: factor.clamp(0.05, 1),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_money(item.revenue)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.items});

  final List<LowStockVariantModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.check_circle_outline,
        message: 'Tất cả sản phẩm đều đủ hàng',
      );
    }
    return Column(
      children: items.take(8).map((item) {
        final color = item.stock <= 5 ? Colors.red : Colors.amber.shade800;
        return ListTile(
          leading: Icon(Icons.warning_amber, color: color),
          title: Text(item.productName),
          subtitle: Text(
            [item.variantName, item.sku].whereType<String>().join(' - '),
          ),
          trailing: Text(
            item.stock.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long,
        message: 'Chưa có đơn hàng gần đây',
      );
    }
    return Column(
      children: orders.map((order) {
        return ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(order.orderNumber),
          subtitle: Text('${order.shippingFullName} - ${order.status.name}'),
          trailing: Text(_money(order.totalAmount)),
        );
      }).toList(),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Products', Icons.shopping_bag, RouteNames.adminProductsPath),
      ('Categories', Icons.category, RouteNames.adminCategoriesPath),
      ('Brands', Icons.verified, RouteNames.adminBrandsPath),
      ('Orders', Icons.local_shipping, RouteNames.adminOrdersPath),
      ('Vouchers', Icons.sell, RouteNames.adminVouchersPath),
      ('Inventory', Icons.warehouse, RouteNames.adminInventoryPath),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((action) {
        return OutlinedButton(
          onPressed: () => context.go(action.$3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.$2),
              const SizedBox(height: 6),
              Text(action.$1, textAlign: TextAlign.center),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

String _money(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${buffer}d';
}
