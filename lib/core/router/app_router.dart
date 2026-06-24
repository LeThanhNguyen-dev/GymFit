import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/menu_providers.dart';
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
import '../../features/products/presentation/screens/category_detail_screen.dart';
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
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/products/admin_products.dart';
import '../../features/admin/orders/admin_orders.dart';
import '../../features/admin/categories/admin_categories.dart';
import '../../features/admin/brands/admin_brands.dart';
import '../../features/admin/coupons/admin_coupons.dart';
import '../../features/admin/reviews/admin_reviews.dart';
import '../../features/admin/dashboard/presentation/inventory_screen.dart';
import '../../features/admin/users/admin_users_screen.dart';
import '../../features/admin/users/admin_user_detail_screen.dart';
import '../../features/admin/shop_registrations/presentation/screens/admin_shop_registrations_screen.dart';
import '../../features/admin/shop_registrations/presentation/screens/admin_shop_detail_screen.dart'
    as shop_reg_detail;
import '../../features/admin/shops/admin_product_moderation_screen.dart';
import '../../features/admin/shops/admin_shops_screen.dart';
import '../../features/admin/shops/admin_shop_detail_screen.dart';
import '../../features/admin/orders/admin_order_detail_screen.dart';
import '../../features/admin/finance/admin_finance_screen.dart';
import '../../features/admin/settings/admin_settings_screen.dart';
import '../../features/products/presentation/screens/compare_screen.dart';
import '../../features/register_shop/presentation/screens/register_shop_screen.dart';
import '../../features/register_shop/data/models/shop_registration_model.dart';
import '../../features/support/presentation/support_list_screen.dart';
import '../../features/chat/presentation/chat_scope.dart';
import '../../features/chat/presentation/screens/chat_conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/presentation/screens/chat_new_conversation_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/store/presentation/screens/store_shell.dart';
import '../../features/store/presentation/screens/store_dashboard/dashboard_screen.dart';
import '../../features/store/presentation/screens/store_products/product_list_screen.dart'
    as store_products;
import '../../features/store/presentation/screens/store_products/product_form_screen.dart'
    as store_products;
import '../../features/store/presentation/screens/store_orders/order_list_screen.dart'
    as store_orders;
import '../../features/store/presentation/screens/store_orders/order_detail_screen.dart'
    as store_orders;
import '../../features/store/presentation/screens/store_finance/finance_screen.dart';
import '../../features/store/presentation/screens/store_settings/settings_screen.dart';
import '../../features/admin/widgets/admin_shell.dart';
import 'route_names.dart';
import '../services/deep_link_service.dart';

final routerNotifierProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<bool>(false);

  var initialFired = false;
  ref.listen(authProvider, (_, next) {
    if (next.status == AuthStatus.uninitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!initialFired) initialFired = true;
      if (notifier.value != (next.status == AuthStatus.authenticated)) {
        notifier.value = next.status == AuthStatus.authenticated;
      }
    });
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final publicRoutes = ['/login', '/register', '/forgot-password'];
      final deepLinkRoutes = ['/reset-password', '/verify-success'];

      final currentAuth = ref.read(authProvider);

      if (currentAuth.status == AuthStatus.uninitialized) return null;

      final isLoggedIn = currentAuth.status == AuthStatus.authenticated;

      if (!isLoggedIn &&
          !publicRoutes.contains(path) &&
          !deepLinkRoutes.contains(path)) {
        return '/login';
      }

      if (isLoggedIn && publicRoutes.contains(path)) {
        final user = currentAuth.user;
        if (user != null) {
          if (user.role == 'admin') return RouteNames.adminDashboardPath;
          if (user.role == 'storeowner' || user.sellerStatus == 'approved') {
            return RouteNames.storeDashboardPath;
          }
        }
        return RouteNames.homePath;
      }

      if (path.startsWith('/admin')) {
        final user = currentAuth.user;
        if (user == null || user.role != 'admin') {
          return RouteNames.homePath;
        }
      }

      if (path.startsWith('/store')) {
        final user = currentAuth.user;
        if (user == null || (user.role != 'storeowner' && user.sellerStatus != 'approved')) {
          return RouteNames.homePath;
        }
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
      builder: (_, _) => const AuthScreen(initialPage: AuthPageType.register),
    ),
    GoRoute(
      path: RouteNames.forgotPasswordPath,
      name: RouteNames.forgotPassword,
      builder: (_, _) =>
          const AuthScreen(initialPage: AuthPageType.forgotPassword),
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
              body: Center(child: Text('Payment data not available.')),
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
          path: '/compare',
          name: 'compare',
          builder: (_, _) => const CompareScreen(),
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
              body: Center(child: Text('Missing review information.')),
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
    GoRoute(
      path: RouteNames.registerShopPath,
      name: RouteNames.registerShop,
      builder: (_, state) {
        final extra = state.extra;
        return RegisterShopScreen(
          existingRegistration: extra is ShopRegistrationModel ? extra : null,
        );
      },
    ),
    GoRoute(
      path: RouteNames.supportListPath,
      name: RouteNames.supportList,
      builder: (_, _) => const SupportListScreen(),
    ),
    GoRoute(
      path: RouteNames.chatInboxPath,
      name: RouteNames.chatInbox,
      builder: (_, _) => const ChatConversationsScreen(scope: ChatScope.customer),
    ),
    GoRoute(
      path: RouteNames.chatNewConversationPath,
      name: RouteNames.chatNewConversation,
      builder: (_, _) => const ChatNewConversationScreen(scope: ChatScope.customer),
    ),
    GoRoute(
      path: RouteNames.chatDetailPath,
      name: RouteNames.chatDetail,
      builder: (_, state) => buildChatDetailScreen(
        scope: ChatScope.customer,
        conversationId: state.pathParameters['id'] ?? '',
        extra: state.extra,
      ),
    ),
    GoRoute(
      path: RouteNames.categoryDetailPath,
      name: RouteNames.categoryDetail,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is MenuItemModel) {
          return CategoryDetailScreen(item: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Category not found')),
        );
      },
    ),
    GoRoute(
      path: RouteNames.serviceDetailPath,
      name: RouteNames.serviceDetail,
      builder: (_, state) =>
          ServiceDetailScreen(slug: state.pathParameters['slug'] ?? ''),
    ),
    // Admin Shell + Routes
    ShellRoute(
      builder: (_, _, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.adminPath,
          name: RouteNames.admin,
          redirect: (_, _) => RouteNames.adminDashboardPath,
        ),
        // 6 main tabs
        GoRoute(
          path: RouteNames.adminDashboardPath,
          name: RouteNames.adminDashboard,
          builder: (_, _) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.adminShopsPath,
          name: RouteNames.adminShops,
          builder: (_, _) => const AdminShopsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminUsersPath,
          name: RouteNames.adminUsers,
          builder: (_, _) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: RouteNames.adminOrdersPath,
          name: RouteNames.adminOrders,
          builder: (_, _) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: RouteNames.adminFinancePath,
          name: RouteNames.adminFinance,
          builder: (_, _) => const AdminFinanceScreen(),
        ),
        GoRoute(
          path: RouteNames.adminSettingsPath,
          name: RouteNames.adminSettings,
          builder: (_, _) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminChatPath,
          name: RouteNames.adminChat,
          builder: (_, _) => const ChatConversationsScreen(scope: ChatScope.admin),
        ),
        GoRoute(
          path: RouteNames.adminChatNewPath,
          name: RouteNames.adminChatNew,
          builder: (_, _) => const ChatNewConversationScreen(scope: ChatScope.admin),
        ),
        GoRoute(
          path: RouteNames.adminChatDetailPath,
          name: RouteNames.adminChatDetail,
          builder: (_, state) => buildChatDetailScreen(
            scope: ChatScope.admin,
            conversationId: state.pathParameters['id'] ?? '',
            extra: state.extra,
          ),
        ),
        // Sub-screens (detail pages)
        GoRoute(
          path: RouteNames.adminShopDetailPath,
          name: RouteNames.adminShopDetail,
          builder: (_, state) =>
              AdminShopDetailScreen(shopId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.adminUserDetailPath,
          name: RouteNames.adminUserDetail,
          builder: (_, state) =>
              AdminUserDetailScreen(userId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.adminOrderDetailPath,
          name: RouteNames.adminOrderDetail,
          builder: (_, state) =>
              AdminOrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: RouteNames.adminDisputesPath,
          name: RouteNames.adminDisputes,
          builder: (_, _) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: RouteNames.adminProductModerationPath,
          name: RouteNames.adminProductModeration,
          builder: (_, _) => const AdminProductModerationScreen(),
        ),
        // Legacy routes (keep backward compat)
        GoRoute(
          path: RouteNames.adminProductsPath,
          name: RouteNames.adminProducts,
          builder: (_, _) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminCategoriesPath,
          name: RouteNames.adminCategories,
          builder: (_, _) => const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: RouteNames.adminBrandsPath,
          name: RouteNames.adminBrands,
          builder: (_, _) => const AdminBrandsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminVouchersPath,
          name: RouteNames.adminVouchers,
          builder: (_, _) => const AdminCouponsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminInventoryPath,
          name: RouteNames.adminInventory,
          builder: (_, _) => const InventoryScreen(),
        ),
        GoRoute(
          path: RouteNames.adminReviewsPath,
          name: RouteNames.adminReviews,
          builder: (_, _) => const AdminReviewsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminShopRegistrationsPath,
          name: RouteNames.adminShopRegistrations,
          builder: (_, _) => const AdminShopRegistrationsScreen(),
        ),
        GoRoute(
          path: RouteNames.adminShopRegistrationsDetailPath,
          name: RouteNames.adminShopRegistrationsDetail,
          builder: (_, state) => shop_reg_detail.AdminShopDetailScreen(
            registrationId: state.pathParameters['id'] ?? '',
          ),
        ),
      ],
    ),
    // Store Owner Shell + Routes
    ShellRoute(
      builder: (_, _, child) => StoreShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.storePath,
          name: RouteNames.store,
          redirect: (_, _) => RouteNames.storeDashboardPath,
        ),
        GoRoute(
          path: RouteNames.storeDashboardPath,
          name: RouteNames.storeDashboard,
          builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.storeProductsPath,
          name: RouteNames.storeProducts,
          builder: (_, _) => const store_products.StoreProductListScreen(),
        ),
        GoRoute(
          path: RouteNames.storeOrdersPath,
          name: RouteNames.storeOrders,
          builder: (_, _) => const store_orders.StoreOrderListScreen(),
        ),
        GoRoute(
          path: RouteNames.storeFinancePath,
          name: RouteNames.storeFinance,
          builder: (_, _) => const FinanceScreen(),
        ),
        GoRoute(
          path: RouteNames.storeSettingsPath,
          name: RouteNames.storeSettings,
          builder: (_, _) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.storeChatPath,
          name: RouteNames.storeChat,
          builder: (_, _) => const ChatConversationsScreen(scope: ChatScope.store),
        ),
        GoRoute(
          path: RouteNames.storeChatNewPath,
          name: RouteNames.storeChatNew,
          builder: (_, _) => const ChatNewConversationScreen(scope: ChatScope.store),
        ),
        GoRoute(
          path: RouteNames.storeChatDetailPath,
          name: RouteNames.storeChatDetail,
          builder: (_, state) => buildChatDetailScreen(
            scope: ChatScope.store,
            conversationId: state.pathParameters['id'] ?? '',
            extra: state.extra,
          ),
        ),
        GoRoute(
          path: RouteNames.storeAddProductPath,
          name: RouteNames.storeAddProduct,
          builder: (_, _) => const store_products.StoreProductFormScreen(),
        ),
        GoRoute(
          path: RouteNames.storeEditProductPath,
          name: RouteNames.storeEditProduct,
          builder: (_, state) => store_products.StoreProductFormScreen(
            productId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: RouteNames.storeOrderDetailPath,
          name: RouteNames.storeOrderDetail,
          builder: (_, state) => store_orders.StoreOrderDetailScreen(
            orderId: state.pathParameters['id'] ?? '',
          ),
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
    if (location == RouteNames.cartPath ||
        location == RouteNames.checkoutPath ||
        location == RouteNames.voucherListPath ||
        location.startsWith('${RouteNames.paymentPath}/') ||
        location == RouteNames.paymentStatusPath) {
      return 1;
    }
    if (location == RouteNames.wishlistPath) return 2;
    if (location == RouteNames.profilePath) return 3;
    return 0;
  }
}
