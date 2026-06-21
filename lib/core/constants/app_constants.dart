class AppConstants {
  const AppConstants._();

  static const useMockAuth = false;  // chỉnh true để teesst thôi nhé còn không thì để false

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oigcpptcdbixpnwqycav.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_jG80ZvjVqynLskXnGnq-Hg_DLUg0cha',
  );

  static const String vnpayTmnCode = 'YC4BRBNY';
  static const String vnpayHashSecret = 'EQLQ6WERR3A3731LSXL5RMQSP1LD0CB0';
  static const String vnpayUrl = String.fromEnvironment('VNPAY_URL', defaultValue: 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html');

  static const productsTable = 'products';
  static const usersTable = 'users';
  static const cartsTable = 'carts';
  static const ordersTable = 'orders';
  static const cartItemsTable = 'cart_items';
  static const couponsTable = 'vouchers';
  static const vouchersTable = 'vouchers';
  static const reviewsTable = 'reviews';
  static const addressesTable = 'addresses';
  static const wishlistItemsTable = 'wishlist_items';
  static const orderItemsTable = 'order_items';
  static const paymentsTable = 'payments';
  static const shippingTrackingTable = 'shipping_tracking';
  static const supportTicketsTable = 'support_tickets';
  static const aiRecommendationLogsTable = 'ai_recommendation_logs';
  static const shopRegistrationsTable = 'shop_registrations';
  static const servicesTable = 'services';

  static const productImagesBucket = 'product-images';
  static const avatarImagesBucket = 'avatars';
  static const reviewImagesBucket = 'review-images';
}
