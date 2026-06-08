import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../models/cart_model.dart';

class CartRepository {
  const CartRepository(this._client, this._productRepository);

  final SupabaseClient _client;
  final ProductRepository _productRepository;

  static const _cartSelect =
      '*, product:products(*, category:categories(id, name, slug), '
      'brand:brands(id, name, slug), images:product_images(*)), '
      'variant:product_variants(*)';

  Future<List<CartItemModel>> getCartItems(String userId) async {
    final rows = await _client
        .from(AppConstants.cartItemsTable)
        .select(_cartSelect)
        .eq('user_id', userId)
        .order('created_at');

    return rows.map((row) => CartItemModel.fromJson(row)).toList();
  }

  Future<void> addToCart(
    String userId,
    String productId,
    String variantId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      throw ArgumentError('Số lượng phải lớn hơn 0.');
    }

    final variant = await _productRepository.getVariantById(variantId);
    if (variant == null) {
      throw StateError('Không tìm thấy phiên bản sản phẩm.');
    }

    final existing = await _client
        .from(AppConstants.cartItemsTable)
        .select('id, quantity')
        .eq('user_id', userId)
        .eq('variant_id', variantId)
        .maybeSingle();

    final currentQuantity = existing == null
        ? 0
        : (existing['quantity'] as num?)?.toInt() ?? 0;
    final nextQuantity = currentQuantity + quantity;

    if (nextQuantity > variant.stock) {
      throw StateError('Số lượng vượt quá tồn kho hiện tại.');
    }

    if (existing == null) {
      await _client.from(AppConstants.cartItemsTable).insert({
        'user_id': userId,
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });
    } else {
      await _client
          .from(AppConstants.cartItemsTable)
          .update({
            'quantity': nextQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      throw ArgumentError('Số lượng phải lớn hơn 0.');
    }

    final item = await _client
        .from(AppConstants.cartItemsTable)
        .select('variant_id')
        .eq('id', cartItemId)
        .single();

    final variant = await _productRepository.getVariantById(
      item['variant_id'].toString(),
    );
    if (variant == null) {
      throw StateError('Không tìm thấy phiên bản sản phẩm.');
    }
    if (newQuantity > variant.stock) {
      throw StateError('Số lượng vượt quá tồn kho hiện tại.');
    }

    await _client
        .from(AppConstants.cartItemsTable)
        .update({
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', cartItemId);
  }

  Future<void> removeItem(String cartItemId) async {
    await _client
        .from(AppConstants.cartItemsTable)
        .delete()
        .eq('id', cartItemId);
  }

  Future<void> clearCart(String userId) async {
    await _client
        .from(AppConstants.cartItemsTable)
        .delete()
        .eq('user_id', userId);
  }

  Future<int> getCartCount(String userId) async {
    final items = await getCartItems(userId);
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  Future<List<CartItemModel>> checkStockAvailability(String userId) async {
    final items = await getCartItems(userId);
    return items.where((item) => !item.isInStock).toList();
  }
}
