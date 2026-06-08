import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  const WishlistRepository(this._client);

  final SupabaseClient _client;

  static const _wishlistSelect =
      '*, product:products(*, category:categories(id, name, slug), '
      'brand:brands(id, name, slug), images:product_images(*), '
      'variants:product_variants(*))';

  Future<List<WishlistItemModel>> getWishlistItems(String userId) async {
    final rows = await _client
        .from(AppConstants.wishlistItemsTable)
        .select(_wishlistSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((row) => WishlistItemModel.fromJson(row)).toList();
  }

  Future<void> addToWishlist(String userId, String productId) async {
    await _client.from(AppConstants.wishlistItemsTable).upsert({
      'user_id': userId,
      'product_id': productId,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    await _client
        .from(AppConstants.wishlistItemsTable)
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<bool> isInWishlist(String userId, String productId) async {
    final row = await _client
        .from(AppConstants.wishlistItemsTable)
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    return row != null;
  }

  Future<int> getWishlistCount(String userId) async {
    final rows = await _client
        .from(AppConstants.wishlistItemsTable)
        .select('id')
        .eq('user_id', userId);
    return rows.length;
  }
}
