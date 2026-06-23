import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/checkout_model.dart';

class CheckoutRepository {
  const CheckoutRepository(this._client);

  final SupabaseClient _client;

  Future<CheckoutResult> createOrder(CheckoutRequest request) async {
    if (request.checkoutData.cartItems.isEmpty) {
      throw StateError('Gio hang dang trong.');
    }

    await _validateStock(request);

    final response = await _client.rpc(
      'create_checkout_order_v2',
      params: {
        'p_user_id': request.userId,
        'p_address': {
          'full_name': request.address.fullName,
          'phone': request.address.phone,
          'address_line1': request.address.addressLine1,
          'address_line2': request.address.addressLine2,
          'ward': request.address.ward,
          'district': request.address.district,
          'city': request.address.city,
          'province': request.address.province,
          'country': request.address.country,
          'postal_code': request.address.postalCode,
        },
        'p_items': request.checkoutData.cartItems.map((item) {
          return {
            'variant_id': item.variantId,
            'quantity': item.quantity,
            if (request.checkoutData.isCartCheckout) 'cart_item_id': item.id,
          };
        }).toList(),
        'p_admin_voucher_id': request.checkoutData.voucher?.id,
        'p_shop_voucher_id': request.checkoutData.shopVoucher?.id,
        'p_shipping_fee': request.shippingFee,
        'p_payment_method': request.paymentMethod,
        'p_note': request.note,
      },
    );

    final row = Map<String, dynamic>.from(response as Map);
    return CheckoutResult(
      orderId: row['order_id'].toString(),
      orderNumber: row['order_number'].toString(),
      paymentId: row['payment_id'].toString(),
      paymentMethod: row['payment_method'].toString(),
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<double> calculateShippingFee(String addressId) async {
    final row = await _client
        .from(AppConstants.addressesTable)
        .select('city')
        .eq('id', addressId)
        .maybeSingle();
    final city = row?['city']?.toString().toLowerCase() ?? '';
    if (city.contains('ho chi minh') || city.contains('hcm')) return 20000;
    return 30000;
  }

  Future<void> _validateStock(CheckoutRequest request) async {
    final variantIds = request.checkoutData.cartItems
        .map((item) => item.variantId)
        .toSet()
        .toList();

    final rows = await _client
        .from('product_variants')
        .select('id, stock, quantity')
        .inFilter('id', variantIds);

    final stockByVariant = <String, int>{
      for (final row in rows)
        row['id'].toString():
            ((row['stock'] ?? row['quantity']) as num?)?.toInt() ?? 0,
    };

    for (final item in request.checkoutData.cartItems) {
      final stock = stockByVariant[item.variantId];
      if (stock == null) {
        throw StateError('Khong tim thay phien ban san pham trong gio hang.');
      }
      if (item.quantity > stock) {
        final name = item.product?.name ?? 'San pham';
        throw StateError('$name khong du ton kho de dat hang.');
      }
    }
  }
}
