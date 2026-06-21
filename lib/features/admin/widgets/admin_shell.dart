import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../auth/providers/auth_providers.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex(location),
            onDestinationSelected: (index) => _onNavigate(context, index),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: IconButton(
                icon: const Icon(Icons.fitness_center),
                tooltip: 'GymFit Admin',
                onPressed: () => context.go('/admin/dashboard'),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.store),
                label: Text('Shops'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified),
                label: Text('Brands'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sell),
                label: Text('Vouchers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.reviews),
                label: Text('Reviews'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warehouse),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: Text('Finance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    tooltip: 'Đăng xuất',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go(RouteNames.homePath);
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/shops')) return 1;
    if (location.startsWith('/admin/products')) return 2;
    if (location.startsWith('/admin/categories')) return 3;
    if (location.startsWith('/admin/brands')) return 4;
    if (location.startsWith('/admin/orders')) return 5;
    if (location.startsWith('/admin/users')) return 6;
    if (location.startsWith('/admin/vouchers')) return 7;
    if (location.startsWith('/admin/reviews')) return 8;
    if (location.startsWith('/admin/inventory')) return 9;
    if (location.startsWith('/admin/finance')) return 10;
    if (location.startsWith('/admin/settings')) return 11;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/admin/dashboard');
      case 1: context.go('/admin/shops');
      case 2: context.go('/admin/products');
      case 3: context.go('/admin/categories');
      case 4: context.go('/admin/brands');
      case 5: context.go('/admin/orders');
      case 6: context.go('/admin/users');
      case 7: context.go('/admin/vouchers');
      case 8: context.go('/admin/reviews');
      case 9: context.go('/admin/inventory');
      case 10: context.go('/admin/finance');
      case 11: context.go('/admin/settings');
    }
  }
}
