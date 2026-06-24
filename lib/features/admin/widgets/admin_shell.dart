import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../auth/providers/auth_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _isSidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (!isMobile) {
      return SizedBox.expand(
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: _currentIndex(location),
                          onDestinationSelected: (index) => _onNavigate(context, index),
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                            NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Chat')),
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
                      ),
                    ),
                  );
                },
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile: overlay sidebar
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (_isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarOpen = false),
                child: Container(color: Colors.black54),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _isSidebarOpen ? 0 : -80,
            top: 0,
            bottom: 0,
            width: 80,
            child: Material(
              elevation: 16,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: _currentIndex(location),
                            onDestinationSelected: (index) {
                              setState(() => _isSidebarOpen = false);
                              _onNavigate(context, index);
                            },
                            labelType: NavigationRailLabelType.all,
                            leading: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: IconButton(
                                icon: const Icon(Icons.fitness_center),
                                tooltip: 'GymFit Admin',
                                onPressed: () {
                                  setState(() => _isSidebarOpen = false);
                                  context.go('/admin/dashboard');
                                },
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
                              NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Chat')),
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
                                  setState(() => _isSidebarOpen = false);
                                  await ref.read(authProvider.notifier).logout();
                                  if (context.mounted) context.go(RouteNames.loginPath);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'admin-sidebar-toggle-fab',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                  child: Icon(_isSidebarOpen ? Icons.close : Icons.menu),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'admin-logout-fab',
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(RouteNames.loginPath);
                  },
                  child: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
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
    if (location.startsWith('/admin/chat')) return 8;
    if (location.startsWith('/admin/reviews')) return 9;
    if (location.startsWith('/admin/inventory')) return 10;
    if (location.startsWith('/admin/finance')) return 11;
    if (location.startsWith('/admin/settings')) return 12;
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
      case 8: context.go(RouteNames.adminChatPath);
      case 9: context.go('/admin/reviews');
      case 10: context.go('/admin/inventory');
      case 11: context.go('/admin/finance');
      case 12: context.go('/admin/settings');
    }
  }
}
