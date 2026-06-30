import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class ProductRepository {
  const ProductRepository(this._client);

  final SupabaseClient _client;

  static const String _productSelect =
      'id, category_id, seller_id, brand_id, name, slug, sku, short_description, description, base_price, compare_at_price, cost_price, status, is_featured, is_digital, requires_shipping, weight_grams, length_cm, width_cm, height_cm, tags, attributes, seo_title, seo_description, average_rating, total_reviews, total_sold, view_count, metadata, created_at, updated_at, category:categories(id, name, slug), brand:brands(id, name, slug), images:product_images(*), variants:product_variants(*)';

  Future<List<ProductModel>> getStoreProducts({required String sellerId, String? search}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('seller_id', sellerId)
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


  static const String _adminProductSelect = _productSelect;

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
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    var q = _client.from(AppConstants.productsTable).select(_productSelect);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.eq('category_id', categoryId);
    }
    if (brandId != null && brandId.isNotEmpty) {
      q = q.eq('brand_id', brandId);
    }
    if (minPrice != null) {
      q = q.gte('base_price', minPrice);
    }
    if (maxPrice != null) {
      q = q.lte('base_price', maxPrice);
    }
    if (search != null && search.trim().isNotEmpty) {
      final keyword = search.trim();
      q = q.or(
        'name.ilike.%$keyword%,sku.ilike.%$keyword%,short_description.ilike.%$keyword%',
      );
    }

    final orderBy = (sortBy != null && sortBy.isNotEmpty) ? sortBy : 'created_at';
    final rows = await q.order(orderBy, ascending: ascending).range(from, to);

    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .map<ProductModel>((row) => ProductModel.fromJson(row))
        .toList();
  }

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .eq('is_featured', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getBestSellers({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .order('total_sold', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getNewArrivals({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getRecommendedProducts({int limit = 10}) async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final response = await _client.functions.invoke(
          'ai-recommendations',
          body: {'user_id': user.id, 'limit': limit},
        );
        if (response.status == 200 && response.data is List) {
          final ids = (response.data as List).map((e) => e.toString()).toList();
          if (ids.isNotEmpty) {
            final rows = await _client
                .from(AppConstants.productsTable)
                .select(_productSelect)
                .inFilter('id', ids);
            return rows.map((row) => ProductModel.fromJson(row)).toList();
          }
        }
      }
    } catch (_) {}

    // Fallback to top rated if no user or AI fails
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .order('average_rating', ascending: false)
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
        .eq('category_id', categoryId)
        .neq('id', productId)
        .order('average_rating', ascending: false)
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
    final keyword = text.trim();
    final formattedKeyword = keyword.split(' ').join(' | ');
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(_productSelect)
        .inFilter('status', ['active', 'out_of_stock'])
        .textSearch('name', formattedKeyword, config: 'english')
        .order('total_sold', ascending: false)
        .limit(50);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<String>> getSearchSuggestions(String text) async {
    if (text.trim().isEmpty) return [];
    final keyword = text.trim();
    try {
      final response = await _client.functions.invoke(
        'ai-search-suggestions',
        body: {'query': keyword},
      );
      if (response.status == 200 && response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    // Fallback if AI function fails or not deployed
    final rows = await _client
        .from(AppConstants.productsTable)
        .select('name')
        .inFilter('status', ['active', 'out_of_stock'])
        .textSearch('name', keyword.split(' ').join(' | '), config: 'english')
        .limit(5);

    return rows.map((row) => row['name'] as String).toList();
  }

  Future<({List<ProductModel> items, int totalCount})> getAdminProducts({
    String? search,
    String? status,
    String? categoryId,
    String? brandId,
    String sortBy = 'created_at',
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    var query = _client.from(AppConstants.productsTable).select(_adminProductSelect);

    if (search != null && search.isNotEmpty) {
      final keyword = search.toLowerCase().trim();
      query = query.or(
        'name.ilike.%$keyword%,sku.ilike.%$keyword%',
      );
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (brandId != null) {
      query = query.eq('brand_id', brandId);
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => ProductModel.fromJson(row)).toList();

    var countQuery = _client.from(AppConstants.productsTable).select('id');
    if (search != null && search.isNotEmpty) {
      final keyword = search.toLowerCase().trim();
      countQuery = countQuery.or(
        'name.ilike.%$keyword%,sku.ilike.%$keyword%',
      );
    }
    if (status != null) {
      countQuery = countQuery.eq('status', status);
    }
    if (categoryId != null) {
      countQuery = countQuery.eq('category_id', categoryId);
    }
    if (brandId != null) {
      countQuery = countQuery.eq('brand_id', brandId);
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
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
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }

  Future<void> deleteProduct(String productId) => softDeleteProduct(productId);

  Future<void> restoreProduct(String productId) async {
    await _client
        .from(AppConstants.productsTable)
        .update({
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }

  Future<({List<CategoryModel> items, int totalCount})> getAdminCategories({
    String? search,
    String sortBy = 'sort_order',
    bool ascending = true,
    int page = 1,
    int pageSize = 50,
  }) async {
    var query = _client.from('categories').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%${search.toLowerCase().trim()}%');
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => CategoryModel.fromJson(row)).toList();

    var countQuery = _client.from('categories').select('id');
    if (search != null && search.isNotEmpty) {
      countQuery = countQuery.ilike('name', '%${search.toLowerCase().trim()}%');
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
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
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', categoryId);
  }

  Future<({List<BrandModel> items, int totalCount})> getAdminBrands({
    String? search,
    String sortBy = 'name',
    bool ascending = true,
    int page = 1,
    int pageSize = 50,
  }) async {
    var query = _client.from('brands').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%${search.toLowerCase().trim()}%');
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => BrandModel.fromJson(row)).toList();

    var countQuery = _client.from('brands').select('id');
    if (search != null && search.isNotEmpty) {
      countQuery = countQuery.ilike('name', '%${search.toLowerCase().trim()}%');
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
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
      'url': imageUrl,
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
