import '../../../cart/data/models/cart_model.dart';
import '../../../address/data/models/address_model.dart';
import '../../../voucher/data/models/voucher_model.dart';

enum CheckoutSource {
  cart,
  buyNow,
}

class CheckoutData {
  const CheckoutData({
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.source = CheckoutSource.cart,
    this.cartItemIds = const [],
    this.voucher,
    this.shopVoucher,
  });

  final List<CartItemModel> cartItems;
  final CheckoutSource source;
  final List<String> cartItemIds;
  final VoucherModel? voucher;
  final VoucherModel? shopVoucher;
  final double subtotal;
  final double discountAmount;
  final double total;

  bool get isBuyNow => source == CheckoutSource.buyNow;
  bool get isCartCheckout => source == CheckoutSource.cart;

  List<VoucherModel> get appliedVouchers => [
    if (voucher != null) voucher!,
    if (shopVoucher != null) shopVoucher!,
  ];

  CheckoutData copyWith({
    List<CartItemModel>? cartItems,
    CheckoutSource? source,
    List<String>? cartItemIds,
    VoucherModel? voucher,
    VoucherModel? shopVoucher,
    bool clearVoucher = false,
    bool clearShopVoucher = false,
    double? subtotal,
    double? discountAmount,
    double? total,
  }) {
    return CheckoutData(
      cartItems: cartItems ?? this.cartItems,
      source: source ?? this.source,
      cartItemIds: cartItemIds ?? this.cartItemIds,
      voucher: clearVoucher ? null : voucher ?? this.voucher,
      shopVoucher: clearShopVoucher ? null : shopVoucher ?? this.shopVoucher,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
    );
  }
}

class CheckoutState {
  const CheckoutState({
    this.selectedAddress,
    this.paymentMethod = 'cod',
    this.note = '',
    this.shippingFee = 30000,
  });

  final AddressModel? selectedAddress;
  final String paymentMethod;
  final String note;
  final double shippingFee;

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    bool clearAddress = false,
    String? paymentMethod,
    String? note,
    double? shippingFee,
  }) {
    return CheckoutState(
      selectedAddress: clearAddress
          ? null
          : selectedAddress ?? this.selectedAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      shippingFee: shippingFee ?? this.shippingFee,
    );
  }
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.userId,
    required this.checkoutData,
    required this.address,
    required this.paymentMethod,
    required this.shippingFee,
    this.note,
  });

  final String userId;
  final CheckoutData checkoutData;
  final AddressModel address;
  final String paymentMethod;
  final double shippingFee;
  final String? note;

  double get totalAmount => checkoutData.total + shippingFee;
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.paymentId,
    required this.paymentMethod,
    required this.totalAmount,
  });

  final String orderId;
  final String orderNumber;
  final String paymentId;
  final String paymentMethod;
  final double totalAmount;
}
