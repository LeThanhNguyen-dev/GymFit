import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../products/data/models/product_model.dart';

class AIRecommendationRepository {
  const AIRecommendationRepository(this._client);

  final SupabaseClient _client;

  Future<List<ProductModel>> getSimilarProducts(
    String productId, {
    int limit = 10,
  }) async {
    final source = await _client
        .from(AppConstants.productsTable)
        .select()
        .eq('id', productId)
        .maybeSingle();
    if (source == null) return const [];

    final product = ProductModel.fromJson(source);
    final lowerPrice = product.basePrice * 0.7;
    final upperPrice = product.basePrice * 1.3;

    final rows = await _client
        .from(AppConstants.productsTable)
        .select(
          '*, category:categories(id, name, slug), brand:brands(id, name, slug), images:product_images(*)',
        )
        .neq('id', productId)
        .gte('base_price', lowerPrice)
        .lte('base_price', upperPrice)
        .limit(limit * 3);

    final scored = rows.map((row) {
      final candidate = ProductModel.fromJson(row);
      var score = 0;
      if (candidate.categoryId == product.categoryId) {
        score += 4;
      }
      if (candidate.brandId != null && candidate.brandId == product.brandId) {
        score += 3;
      }
      score += candidate.averageRating.round();
      score += (candidate.totalSold / 10).floor();
      return MapEntry(candidate, score);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).take(limit).toList();
  }

  Future<List<ProductModel>> getAlsoBoughtProducts(
    String productId, {
    int limit = 10,
  }) async {
    final orderItems = await _client
        .from(AppConstants.orderItemsTable)
        .select('order_id')
        .eq('product_id', productId)
        .limit(100);
    final orderIds = orderItems
        .map((row) => row['order_id'].toString())
        .toSet()
        .toList();
    if (orderIds.isEmpty) return const [];

    final relatedItems = await _client
        .from(AppConstants.orderItemsTable)
        .select('product_id')
        .inFilter('order_id', orderIds)
        .neq('product_id', productId);
    final frequency = <String, int>{};
    for (final row in relatedItems) {
      final id = row['product_id']?.toString();
      if (id != null && id.isNotEmpty) {
        frequency[id] = (frequency[id] ?? 0) + 1;
      }
    }
    final productIds = frequency.keys.toList()
      ..sort((a, b) => (frequency[b] ?? 0).compareTo(frequency[a] ?? 0));
    if (productIds.isEmpty) return const [];

    final rows = await _client
        .from(AppConstants.productsTable)
        .select('*, images:product_images(*)')
        .inFilter('id', productIds.take(limit).toList());
    final products = rows.map((row) => ProductModel.fromJson(row)).toList();
    products.sort(
      (a, b) => productIds.indexOf(a.id).compareTo(productIds.indexOf(b.id)),
    );
    return products;
  }

  Future<List<ProductModel>> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    final wishlistRows = await _client
        .from(AppConstants.wishlistItemsTable)
        .select('product_id')
        .eq('user_id', userId)
        .limit(50);
    final wishlistIds = wishlistRows
        .map((row) => row['product_id'].toString())
        .toSet();

    final orderedItems = await _client
        .from(AppConstants.orderItemsTable)
        .select('product_id')
        .limit(100);
    final purchasedIds = orderedItems
        .map((row) => row['product_id'].toString())
        .toSet();

    final seedIds = {
      ...wishlistIds,
      ...purchasedIds,
    }.where((id) => id.isNotEmpty).toList();
    if (seedIds.isEmpty) return getTrendingProducts(limit: limit);

    final seedProducts = await _client
        .from(AppConstants.productsTable)
        .select('category_id')
        .inFilter('id', seedIds);
    final categoryFrequency = <String, int>{};
    for (final row in seedProducts) {
      final categoryId = row['category_id']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        categoryFrequency[categoryId] =
            (categoryFrequency[categoryId] ?? 0) + 1;
      }
    }
    final categoryIds = categoryFrequency.keys.toList()
      ..sort(
        (a, b) =>
            (categoryFrequency[b] ?? 0).compareTo(categoryFrequency[a] ?? 0),
      );
    if (categoryIds.isEmpty) return getTrendingProducts(limit: limit);

    final rows = await _client
        .from(AppConstants.productsTable)
        .select('*, images:product_images(*)')
        .inFilter('category_id', categoryIds.take(3).toList())
        .not('id', 'in', seedIds)
        .order('total_sold', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<List<ProductModel>> getTrendingProducts({
    int limit = 10,
    int days = 7,
  }) async {
    final from = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await _client
        .from(AppConstants.productsTable)
        .select('*, images:product_images(*)')
        .gte('created_at', from)
        .order('total_sold', ascending: false)
        .limit(limit);

    return rows.map((row) => ProductModel.fromJson(row)).toList();
  }

  Future<void> logRecommendation(
    String userId,
    String? sourceProductId,
    List<String> recommendedIds,
    String type, {
    String? clickedProductId,
  }) async {
    await _client.from(AppConstants.aiRecommendationLogsTable).insert({
      'user_id': userId,
      'source_product_id': sourceProductId,
      'recommended_ids': recommendedIds,
      'type': type,
      'clicked_product_id': clickedProductId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
