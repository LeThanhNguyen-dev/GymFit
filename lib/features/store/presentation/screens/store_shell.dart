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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (i) {
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
              GoRouter.of(context).go(RouteNames.storeChatPath);
            case 5:
              GoRouter.of(context).go(RouteNames.storeSettingsPath);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance),
            label: 'Tài chính',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
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
    if (loc == RouteNames.storeChatPath ||
        loc == RouteNames.storeChatNewPath ||
        loc == RouteNames.storeChatDetailPath) {
      return 4;
    }
    if (loc == RouteNames.storeSettingsPath) {
      return 5;
    }
    return 0;
  }
}
