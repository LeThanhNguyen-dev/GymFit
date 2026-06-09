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

  // Admin
  static const String admin = 'admin';
  static const String adminDashboard = 'adminDashboard';
  static const String adminProducts = 'adminProducts';
  static const String adminCategories = 'adminCategories';
  static const String adminBrands = 'adminBrands';
  static const String adminOrders = 'adminOrders';
  static const String adminVouchers = 'adminVouchers';
  static const String adminInventory = 'adminInventory';
  static const String adminUsers = 'adminUsers';
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
  static const String adminPath = '/admin';
  static const String adminDashboardPath = '/admin/dashboard';
  static const String adminProductsPath = '/admin/products';
  static const String adminCategoriesPath = '/admin/categories';
  static const String adminBrandsPath = '/admin/brands';
  static const String adminOrdersPath = '/admin/orders';
  static const String adminVouchersPath = '/admin/vouchers';
  static const String adminInventoryPath = '/admin/inventory';
  static const String adminUsersPath = '/admin/users';
  static const String adminReviewsPath = '/admin/reviews';
}
