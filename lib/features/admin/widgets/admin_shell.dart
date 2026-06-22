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
    final currentIdx = _currentIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildRail(context, ref, location, currentIdx);
        }
        return _buildMobile(context, ref, location, currentIdx);
      },
    );
  }

  Widget _buildRail(BuildContext context, WidgetRef ref, String location, int currentIdx) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIdx,
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
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.store), label: Text('Shops')),
              NavigationRailDestination(icon: Icon(Icons.shopping_bag), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.category), label: Text('Categories')),
              NavigationRailDestination(icon: Icon(Icons.verified), label: Text('Brands')),
              NavigationRailDestination(icon: Icon(Icons.local_shipping), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Users')),
              NavigationRailDestination(icon: Icon(Icons.sell), label: Text('Vouchers')),
              NavigationRailDestination(icon: Icon(Icons.reviews), label: Text('Reviews')),
              NavigationRailDestination(icon: Icon(Icons.warehouse), label: Text('Inventory')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Finance')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(RouteNames.loginPath);
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, String location, int currentIdx) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(_labelForIndex(currentIdx)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.fitness_center, size: 40),
                  const SizedBox(height: 8),
                  Text('GymFit Admin', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            ...List.generate(_destinations.length, (i) {
              final d = _destinations[i];
              return ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: i == currentIdx,
                onTap: () {
                  scaffoldKey.currentState?.closeDrawer();
                  _onNavigate(context, i);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất'),
              onTap: () async {
                scaffoldKey.currentState?.closeDrawer();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(RouteNames.loginPath);
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  static const _destinations = [
    _NavItem(Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.store, 'Shops'),
    _NavItem(Icons.shopping_bag, 'Products'),
    _NavItem(Icons.category, 'Categories'),
    _NavItem(Icons.verified, 'Brands'),
    _NavItem(Icons.local_shipping, 'Orders'),
    _NavItem(Icons.people, 'Users'),
    _NavItem(Icons.sell, 'Vouchers'),
    _NavItem(Icons.reviews, 'Reviews'),
    _NavItem(Icons.warehouse, 'Inventory'),
    _NavItem(Icons.account_balance_wallet, 'Finance'),
    _NavItem(Icons.settings, 'Settings'),
  ];

  String _labelForIndex(int i) => _destinations[i].label;

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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
