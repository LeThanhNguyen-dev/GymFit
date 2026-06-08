import '../../../cart/data/models/cart_model.dart';
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
}
