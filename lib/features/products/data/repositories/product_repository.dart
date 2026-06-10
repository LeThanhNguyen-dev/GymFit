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

  Future<List<ProductModel>> getAdminProducts({String? search}) async {
    final rows = await _client
        .from(AppConstants.productsTable)
        .select(
          '*, category:categories(id, name, slug), '
          'brand:brands(id, name, slug), images:product_images(*), '
          'variants:product_variants(*)',
        )
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
              .select()
              .single()
        : await _client
              .from(AppConstants.productsTable)
              .update(payload)
              .eq('id', id)
              .select()
              .single();

    return ProductModel.fromJson(row);
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
}
