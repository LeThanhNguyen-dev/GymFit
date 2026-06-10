import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

final routerNotifierProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<bool>(false);
  final authState = ref.watch(authProvider);

  if (authState.status == AuthStatus.authenticated) {
    notifier.value = true;
  }

  ref.listen(authProvider, (_, next) {
    notifier.value = next.status == AuthStatus.authenticated;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.value;
      final path = state.matchedLocation;

      final publicRoutes = ['/login', '/register', '/forgot-password', '/reset-password'];

      if (!isLoggedIn && !publicRoutes.contains(path)) {
        return '/login';
      }

      if (isLoggedIn && publicRoutes.contains(path)) {
        return '/';
      }

      return null;
    },
    routes: _buildRoutes(),
  );
});

List<RouteBase> _buildRoutes() {
  return [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgotPassword',
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'resetPassword',
      builder: (_, _) => const ResetPasswordScreen(),
    ),
    ShellRoute(
      builder: (_, _, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (_, _) => const _PlaceholderScreen(title: 'Home'),
        ),
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (_, _) => const _PlaceholderScreen(title: 'Cart'),
        ),
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          builder: (_, _) => const _PlaceholderScreen(title: 'Wishlist'),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (_, _) => const _PlaceholderScreen(title: 'Profile'),
        ),
      ],
    ),
  ];
}

class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              GoRouter.of(context).go('/cart');
            case 2:
              GoRouter.of(context).go('/wishlist');
            case 3:
              GoRouter.of(context).go('/profile');
            default:
              GoRouter.of(context).go('/');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Giỏ hàng'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Yêu thích'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/cart') return 1;
    if (location == '/wishlist') return 2;
    if (location == '/profile') return 3;
    return 0;
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen - sẽ được implement sau')),
    );
  }
}
