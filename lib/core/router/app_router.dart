import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/data/models/checkout_model.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../features/payments/presentation/screens/payment_status_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/shipping/presentation/screens/shipping_tracking_screen.dart';
import '../../features/voucher/presentation/screens/voucher_list_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/address_list_screen.dart';
import '../../features/reviews/presentation/screens/review_form_screen.dart';
import 'route_names.dart';
import '../services/deep_link_service.dart';

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
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.value;
      final path = state.matchedLocation;

      final publicRoutes = ['/login', '/register', '/forgot-password'];
      final deepLinkRoutes = ['/reset-password', '/verify-success'];

      if (!isLoggedIn &&
          !publicRoutes.contains(path) &&
          !deepLinkRoutes.contains(path)) {
        return '/login';
      }

      if (isLoggedIn && publicRoutes.contains(path)) {
        return RouteNames.homePath;
      }

      return null;
    },
    routes: _buildRoutes(),
  );
});

List<RouteBase> _buildRoutes() {
  return [
    GoRoute(
      path: RouteNames.loginPath,
      name: RouteNames.login,
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: RouteNames.registerPath,
      name: RouteNames.register,
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'resetPassword',
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/verify-success',
      name: 'verifySuccess',
      builder: (_, _) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (_, _, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.homePath,
          name: RouteNames.home,
          builder: (_, _) => const HomeScreen(),
        ),
        GoRoute(
          path: RouteNames.cartPath,
          name: RouteNames.cart,
          builder: (_, _) => const CartScreen(),
        ),
        GoRoute(
          path: RouteNames.checkoutPath,
          name: RouteNames.checkout,
          builder: (_, state) => CheckoutScreen(
            initialData: state.extra is CheckoutData
                ? state.extra! as CheckoutData
                : null,
          ),
        ),
        GoRoute(
          path: RouteNames.orderHistoryPath,
          name: RouteNames.orderHistory,
          builder: (_, _) => const OrdersScreen(),
        ),
        GoRoute(
          path: RouteNames.orderDetailPath,
          name: RouteNames.orderDetail,
          builder: (_, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.paymentStatusPath,
          name: RouteNames.paymentStatus,
          builder: (_, state) {
            final extra = state.extra;
            if (extra is Map &&
                extra['payment'] is PaymentModel &&
                extra['orderId'] is String) {
              return PaymentStatusScreen(
                payment: extra['payment'] as PaymentModel,
                orderId: extra['orderId'] as String,
              );
            }

            return const Scaffold(
              body: Center(
                child: Text('Khong co du lieu trang thai thanh toan.'),
              ),
            );
          },
        ),
        GoRoute(
          path: '${RouteNames.paymentPath}/:orderId',
          name: RouteNames.payment,
          builder: (_, state) =>
              PaymentScreen(orderId: state.pathParameters['orderId'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.shippingTrackingPath,
          name: RouteNames.shippingTracking,
          builder: (_, state) => ShippingTrackingScreen(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
        ),
        GoRoute(
          path: RouteNames.voucherListPath,
          name: RouteNames.voucherList,
          builder: (_, state) {
            final amount = state.extra;
            return VoucherListScreen(
              orderAmount: amount is num ? amount.toDouble() : 0,
            );
          },
        ),
        GoRoute(
          path: RouteNames.productListPath,
          name: RouteNames.productList,
          builder: (_, state) {
            final extra = state.extra;
            final filters = extra is Map ? extra : const {};
            return ProductListScreen(
              categoryId: filters['categoryId']?.toString(),
              brandId: filters['brandId']?.toString(),
              title: filters['title']?.toString(),
            );
          },
        ),
        GoRoute(
          path: RouteNames.productDetailPath,
          name: RouteNames.productDetail,
          builder: (_, state) =>
              ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.searchPath,
          name: RouteNames.search,
          builder: (_, _) => const SearchScreen(),
        ),
        GoRoute(
          path: RouteNames.wishlistPath,
          name: RouteNames.wishlist,
          builder: (_, _) => const WishlistScreen(),
        ),
        GoRoute(
          path: RouteNames.profilePath,
          name: RouteNames.profile,
          builder: (_, _) => const ProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.reviewFormPath,
          name: RouteNames.reviewForm,
          builder: (_, state) {
            final extra = state.extra;
            if (extra is Map) {
              return ReviewFormScreen(
                productId: extra['productId']?.toString() ?? '',
                orderId: extra['orderId']?.toString() ?? '',
                productName: extra['productName']?.toString() ?? '',
                productImageUrl: extra['productImageUrl']?.toString(),
              );
            }
            return const Scaffold(
              body: Center(child: Text('Thiếu thông tin để viết đánh giá.')),
            );
          },
        ),
      ],
    ),
    // User profile sub-routes (no bottom nav)
    GoRoute(
      path: RouteNames.editProfilePath,
      name: RouteNames.editProfile,
      builder: (_, _) => const EditProfileScreen(),
    ),
    GoRoute(
      path: RouteNames.addressListPath,
      name: RouteNames.addressList,
      builder: (_, _) => const AddressListScreen(),
    ),
    GoRoute(
      path: RouteNames.addAddressPath,
      name: RouteNames.addAddress,
      builder: (_, _) => const AddressListScreen(),
    ),
    GoRoute(
      path: RouteNames.editAddressPath,
      name: RouteNames.editAddress,
      builder: (_, _) => const AddressListScreen(),
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
              GoRouter.of(context).go(RouteNames.cartPath);
            case 2:
              GoRouter.of(context).go(RouteNames.wishlistPath);
            case 3:
              GoRouter.of(context).go(RouteNames.profilePath);
            default:
              GoRouter.of(context).go(RouteNames.homePath);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == RouteNames.cartPath) return 1;
    if (location == RouteNames.wishlistPath) return 2;
    if (location == RouteNames.profilePath) return 3;
    return 0;
  }
}

