import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class ProductRepository {
  const ProductRepository(this._client);

  final SupabaseClient _client;

  static const String _productSelect =
      '*, category:categories(id, name, slug), '
      'brand:brands(id, name, slug), images:product_images(*), '
      'variants:product_variants(*)';

  Future<ProductModel?> getProductById(String productId) async {
    final row = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
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

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool ascending = true,
    String? search,
  }) async {
    dynamic query = _client.from(AppConstants.productsTable).select(_productSelect);

    // Filter by active products only for customers
    query = query.eq('is_active', true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    if (brandId != null && brandId.isNotEmpty) {
      query = query.eq('brand_id', brandId);
    }

    if (minPrice != null) {
      query = query.gte('base_price', minPrice);
    }

    if (maxPrice != null) {
      query = query.lte('base_price', maxPrice);
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    // Sorting
    if (sortBy != null && sortBy.isNotEmpty) {
      query = query.order(sortBy, ascending: ascending);
    } else {
      query = query.order('created_at', ascending: false);
    }

    // Pagination
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    query = query.range(from, to);

    final rows = await query;
    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getBestSellers({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .order('total_sold', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getNewArrivals({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 10,
  }) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .eq('category_id', categoryId)
        .neq('id', productId)
        .order('avg_rating', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .inFilter('id', ids);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> searchProducts(String text) async {
    if (text.isEmpty) return [];
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .ilike('name', '%$text%')
        .order('created_at', ascending: false);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  // --- Admin Methods ---

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final row = await _client
        .from(AppConstants.productsTable)
        .insert(data)
        .select(_productSelect)
        .single();

    return ProductModel.fromJson(row);
  }

  Future<ProductModel> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from(AppConstants.productsTable)
        .update(data)
        .eq('id', productId)
        .select(_productSelect)
        .single();

    return ProductModel.fromJson(row);
  }

  Future<void> deleteProduct(String productId) async {
    // Soft delete by setting is_active to false
    await _client
        .from(AppConstants.productsTable)
        .update({'is_active': false}).eq('id', productId);
  }

  Future<void> addProductImage(
    String productId,
    String imageUrl,
    int sortOrder,
  ) async {
    await _client.from('product_images').insert({
      'product_id': productId,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    });
  }

  Future<void> removeProductImage(String imageId) async {
    await _client.from('product_images').delete().eq('id', imageId);
  }

  Future<ProductVariantModel> createVariant(Map<String, dynamic> data) async {
    final row = await _client
        .from('product_variants')
        .insert(data)
        .select()
        .single();

    return ProductVariantModel.fromJson(row);
  }

  Future<ProductVariantModel> updateVariant(
    String variantId,
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from('product_variants')
        .update(data)
        .eq('id', variantId)
        .select()
        .single();

    return ProductVariantModel.fromJson(row);
  }

  Future<void> deleteVariant(String variantId) async {
    await _client.from('product_variants').delete().eq('id', variantId);
  }

  Future<void> updateStock(String variantId, int newStock) async {
    await _client
        .from('product_variants')
        .update({'stock': newStock, 'quantity': newStock}).eq('id', variantId);
  }

  Future<void> updateProductRating(
    String productId,
    double avgRating,
    int totalReviews,
  ) async {
    await _client.from(AppConstants.productsTable).update({
      'avg_rating': avgRating,
      'average_rating': avgRating,
      'total_reviews': totalReviews,
    }).eq('id', productId);
  }
}
