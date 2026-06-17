import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/products')) return 1;
    if (location.startsWith('/admin/categories')) return 2;
    if (location.startsWith('/admin/brands')) return 3;
    if (location.startsWith('/admin/orders')) return 4;
    if (location.startsWith('/admin/users')) return 5;
    if (location.startsWith('/admin/vouchers')) return 6;
    if (location.startsWith('/admin/reviews')) return 7;
    if (location.startsWith('/admin/inventory')) return 8;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/admin/dashboard');
      case 1: context.go('/admin/products');
      case 2: context.go('/admin/categories');
      case 3: context.go('/admin/brands');
      case 4: context.go('/admin/orders');
      case 5: context.go('/admin/users');
      case 6: context.go('/admin/vouchers');
      case 7: context.go('/admin/reviews');
      case 8: context.go('/admin/inventory');
    }
  }
}
