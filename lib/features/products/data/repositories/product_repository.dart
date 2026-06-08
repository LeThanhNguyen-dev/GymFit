import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class ProductRepository {
  const ProductRepository(this._client);

  final SupabaseClient _client;

  Future<ProductModel?> getProductById(String productId) async {
    final row = await _client
        .from(AppConstants.productsTable)
        .select(
          '*, category:categories(id, name, slug), '
          'brand:brands(id, name, slug), images:product_images(*), '
          'variants:product_variants(*)',
        )
        .eq('id', productId)
        .maybeSingle();

    return row == null ? null : ProductModel.fromJson(row);
  }

  Future<ProductVariantModel?> getVariantById(String variantId) async {
    final row = await _client
        .from('product_variants')
        .select()
        .eq('id', variantId)
        .maybeSingle();

    return row == null ? null : ProductVariantModel.fromJson(row);
  }
}
