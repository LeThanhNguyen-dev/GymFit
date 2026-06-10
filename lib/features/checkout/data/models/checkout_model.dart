import '../../../cart/data/models/cart_model.dart';
import '../../../address/data/models/address_model.dart';
import '../../../voucher/data/models/voucher_model.dart';

class CheckoutData {
  const CheckoutData({
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.voucher,
  });

  final List<CartItemModel> cartItems;
  final VoucherModel? voucher;
  final double subtotal;
  final double discountAmount;
  final double total;

  CheckoutData copyWith({
    List<CartItemModel>? cartItems,
    VoucherModel? voucher,
    bool clearVoucher = false,
    double? subtotal,
    double? discountAmount,
    double? total,
  }) {
    return CheckoutData(
      cartItems: cartItems ?? this.cartItems,
      voucher: clearVoucher ? null : voucher ?? this.voucher,
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
