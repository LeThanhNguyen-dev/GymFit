class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';

  // Main tabs (ShellRoute)
  static const String home = 'home';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';
  static const String profile = 'profile';

  // Product
  static const String productList = 'productList';
  static const String productDetail = 'productDetail';
  static const String search = 'search';

  // Checkout & Order
  static const String checkout = 'checkout';
  static const String orderHistory = 'orderHistory';
  static const String orderDetail = 'orderDetail';

  // User
  static const String editProfile = 'editProfile';
  static const String addressList = 'addressList';
  static const String addAddress = 'addAddress';
  static const String editAddress = 'editAddress';

  // Voucher
  static const String voucherList = 'voucherList';

  // Payment
  static const String payment = 'payment';
  static const String paymentStatus = 'paymentStatus';

  // Shipping
  static const String shippingTracking = 'shippingTracking';

  // Review
  static const String reviewForm = 'reviewForm';

  // Support
  static const String supportList = 'supportList';
  static const String supportDetail = 'supportDetail';

  // Shop Registration
  static const String registerShop = 'registerShop';

  // Store Owner
  static const String store = 'store';
  static const String storeDashboard = 'storeDashboard';
  static const String storeProducts = 'storeProducts';
  static const String storeOrders = 'storeOrders';
  static const String storeFinance = 'storeFinance';
  static const String storeSettings = 'storeSettings';
  static const String storeAddProduct = 'storeAddProduct';
  static const String storeEditProduct = 'storeEditProduct';
  static const String storeOrderDetail = 'storeOrderDetail';

  // Admin — 6 tabs
  static const String admin = 'admin';
  static const String adminDashboard = 'adminDashboard';
  static const String adminShops = 'adminShops';
  static const String adminUsers = 'adminUsers';
  static const String adminOrders = 'adminOrders';
  static const String adminFinance = 'adminFinance';
  static const String adminSettings = 'adminSettings';

  // Admin sub-screens
  static const String adminShopDetail = 'adminShopDetail';
  static const String adminShopRegistrations = 'adminShopRegistrations';
  static const String adminShopRegistrationsDetail =
      'adminShopRegistrationsDetail';
  static const String adminProductModeration = 'adminProductModeration';
  static const String adminUserDetail = 'adminUserDetail';
  static const String adminOrderDetail = 'adminOrderDetail';
  static const String adminDisputes = 'adminDisputes';
  static const String adminDisputeDetail = 'adminDisputeDetail';
  static const String adminWithdrawalDetail = 'adminWithdrawalDetail';

  // Legacy (keep for backward compat)
  static const String adminProducts = 'adminProducts';
  static const String adminCategories = 'adminCategories';
  static const String adminBrands = 'adminBrands';
  static const String adminVouchers = 'adminVouchers';
  static const String adminInventory = 'adminInventory';
  static const String adminReviews = 'adminReviews';

  // Route paths
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String resetPasswordPath = '/reset-password';
  static const String homePath = '/';
  static const String cartPath = '/cart';
  static const String wishlistPath = '/wishlist';
  static const String profilePath = '/profile';
  static const String productListPath = '/products';
  static const String productDetailPath = '/products/:id';
  static const String searchPath = '/search';
  static const String checkoutPath = '/checkout';
  static const String orderHistoryPath = '/orders';
  static const String orderDetailPath = '/orders/:id';
  static const String editProfilePath = '/profile/edit';
  static const String addressListPath = '/addresses';
  static const String addAddressPath = '/addresses/add';
  static const String editAddressPath = '/addresses/:id/edit';
  static const String voucherListPath = '/vouchers';
  static const String paymentPath = '/payment';
  static const String paymentStatusPath = '/payment/status';
  static const String shippingTrackingPath = '/shipping/:orderId';
  static const String reviewFormPath = '/review';
  static const String supportListPath = '/support';
  static const String supportDetailPath = '/support/:id';
  static const String registerShopPath = '/register-shop';
  static const String adminPath = '/admin';
  static const String adminDashboardPath = '/admin/dashboard';
  static const String adminShopsPath = '/admin/shops';
  static const String adminUsersPath = '/admin/users';
  static const String adminOrdersPath = '/admin/orders';
  static const String adminFinancePath = '/admin/finance';
  static const String adminSettingsPath = '/admin/settings';

  // Admin sub paths
  static const String adminShopDetailPath = '/admin/shops/:id';
  static const String adminShopRegistrationsPath = '/admin/shop-registrations';
  static const String adminShopRegistrationsDetailPath =
      '/admin/shop-registrations/:id';
  static const String adminProductModerationPath = '/admin/product-moderation';
  static const String adminUserDetailPath = '/admin/users/:id';
  static const String adminOrderDetailPath = '/admin/orders/:id';
  static const String adminDisputesPath = '/admin/disputes';
  static const String adminDisputeDetailPath = '/admin/disputes/:id';
  static const String adminWithdrawalDetailPath = '/admin/withdrawals/:id';

  // Legacy paths
  static const String adminProductsPath = '/admin/products';
  static const String adminCategoriesPath = '/admin/categories';
  static const String adminBrandsPath = '/admin/brands';
  static const String adminVouchersPath = '/admin/vouchers';
  static const String adminInventoryPath = '/admin/inventory';
  static const String adminReviewsPath = '/admin/reviews';

  // Categories
  static const String categoryDetail = 'categoryDetail';
  static const String categoryDetailPath = '/categories/:slug';

  // Services
  static const String serviceDetail = 'serviceDetail';
  static const String serviceDetailPath = '/services/:slug';

  // Shop products (public)
  static const String shopProducts = 'shopProducts';
  static const String shopProductsPath = '/shop-products';

  // Store Owner paths
  static const String storePath = '/store';
  static const String storeDashboardPath = '/store/dashboard';
  static const String storeProductsPath = '/store/products';
  static const String storeOrdersPath = '/store/orders';
  static const String storeFinancePath = '/store/finance';
  static const String storeSettingsPath = '/store/settings';
  static const String storeAddProductPath = '/store/products/add';
  static const String storeEditProductPath = '/store/products/:id/edit';
  static const String storeOrderDetailPath = '/store/orders/:id';
}
