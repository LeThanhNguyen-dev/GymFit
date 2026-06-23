import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';

class StoreShell extends StatelessWidget {
  const StoreShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = _tabIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              GoRouter.of(context).go(RouteNames.storeDashboardPath);
            case 1:
              GoRouter.of(context).go(RouteNames.storeProductsPath);
            case 2:
              GoRouter.of(context).go(RouteNames.storeOrdersPath);
            case 3:
              GoRouter.of(context).go(RouteNames.storeFinancePath);
            case 4:
              GoRouter.of(context).go(RouteNames.storeSettingsPath);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Sản phẩm',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  int _tabIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc == RouteNames.storeProductsPath ||
        loc == RouteNames.storeAddProductPath ||
        loc == RouteNames.storeEditProductPath) {
      return 1;
    }
    if (loc == RouteNames.storeOrdersPath ||
        loc == RouteNames.storeOrderDetailPath) {
      return 2;
    }
    if (loc == RouteNames.storeFinancePath) return 3;
    if (loc == RouteNames.storeSettingsPath) return 4;
    return 0;
  }
}
