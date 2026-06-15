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
    dynamic query = _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true);

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
    if (search != null && search.trim().isNotEmpty) {
      query = query.textSearch('name', search.trim(),
          type: TextSearchType.websearch);
    }

    query = sortBy == null || sortBy.isEmpty
        ? query.order('created_at', ascending: false)
        : query.order(sortBy, ascending: ascending);

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.range(from, to);
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
    if (text.trim().isEmpty) return [];
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_active', true)
        .textSearch('name', text.trim(), type: TextSearchType.websearch)
        .order('created_at', ascending: false);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getAdminProducts({String? search}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .order('created_at', ascending: false);

    final products = rows.map((row) => ProductModel.fromJson(row)).toList();
    if (search == null || search.trim().isEmpty) return products;

    final keyword = search.toLowerCase().trim();
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(keyword) ||
              (product.sku ?? '').toLowerCase().contains(keyword),
        )
        .toList();
  }

  Future<ProductModel> saveProduct(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final payload = {...data, 'updated_at': DateTime.now().toIso8601String()};
    final row = id == null
        ? await _client
              .from(AppConstants.productsTable)
              .insert(payload)
              .select(_productSelect)
              .single()
        : await _client
              .from(AppConstants.productsTable)
              .update(payload)
              .eq('id', id)
              .select(_productSelect)
              .single();

    return ProductModel.fromJson(row);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    return saveProduct(data);
  }

  Future<ProductModel> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    return saveProduct(data, id: productId);
  }

  Future<void> softDeleteProduct(String productId) async {
    await _client
        .from(AppConstants.productsTable)
        .update({
          'status': 'inactive',
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }

  Future<void> deleteProduct(String productId) => softDeleteProduct(productId);

  Future<List<CategoryModel>> getAdminCategories({String? search}) async {
    final rows = await _client.from('categories').select().order('sort_order');
    final categories = rows.map((row) => CategoryModel.fromJson(row)).toList();
    if (search == null || search.trim().isEmpty) return categories;

    final keyword = search.toLowerCase().trim();
    return categories
        .where((category) => category.name.toLowerCase().contains(keyword))
        .toList();
  }

  Future<CategoryModel> saveCategory(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final payload = {...data, 'updated_at': DateTime.now().toIso8601String()};
    final row = id == null
        ? await _client.from('categories').insert(payload).select().single()
        : await _client
              .from('categories')
              .update(payload)
              .eq('id', id)
              .select()
              .single();
    return CategoryModel.fromJson(row);
  }

  Future<void> softDeleteCategory(String categoryId) async {
    await _client
        .from('categories')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', categoryId);
  }

  Future<List<BrandModel>> getAdminBrands({String? search}) async {
    final rows = await _client.from('brands').select().order('name');
    final brands = rows.map((row) => BrandModel.fromJson(row)).toList();
    if (search == null || search.trim().isEmpty) return brands;

    final keyword = search.toLowerCase().trim();
    return brands
        .where((brand) => brand.name.toLowerCase().contains(keyword))
        .toList();
  }

  Future<BrandModel> saveBrand(Map<String, dynamic> data, {String? id}) async {
    final payload = {...data, 'updated_at': DateTime.now().toIso8601String()};
    final row = id == null
        ? await _client.from('brands').insert(payload).select().single()
        : await _client
              .from('brands')
              .update(payload)
              .eq('id', id)
              .select()
              .single();
    return BrandModel.fromJson(row);
  }

  Future<void> softDeleteBrand(String brandId) async {
    await _client
        .from('brands')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', brandId);
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
        .update({'stock': newStock, 'quantity': newStock})
        .eq('id', variantId);
  }

  Future<void> updateProductRating(
    String productId,
    double avgRating,
    int totalReviews,
  ) async {
    await _client
        .from(AppConstants.productsTable)
        .update({
          'avg_rating': avgRating,
          'average_rating': avgRating,
          'total_reviews': totalReviews,
        })
        .eq('id', productId);
  }
}
