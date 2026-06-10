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

    final response = await _client.rpc(
      'create_checkout_order',
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
          final product = item.product;
          final variant = item.variant;
          final unitPrice = variant?.price ?? product?.basePrice ?? 0;
          return {
            'product_id': item.productId,
            'variant_id': item.variantId,
            'product_name': product?.name ?? 'San pham',
            'variant_name': variant?.optionDisplay ?? variant?.name,
            'sku': variant?.sku,
            'image_url': variant?.imageUrl ?? product?.primaryImageUrl,
            'unit_price': unitPrice,
            'quantity': item.quantity,
          };
        }).toList(),
        'p_voucher_id': request.checkoutData.voucher?.id,
        'p_voucher_code': request.checkoutData.voucher?.code,
        'p_subtotal': request.checkoutData.subtotal,
        'p_discount_amount': request.checkoutData.discountAmount,
        'p_shipping_fee': request.shippingFee,
        'p_total_amount': request.totalAmount,
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
}
