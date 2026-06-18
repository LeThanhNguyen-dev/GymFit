import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/review_model.dart';

class ReviewRepository {
  const ReviewRepository(this._client);

  final SupabaseClient _client;

  Future<List<ReviewModel>> getProductReviews(
    String productId, {
    int page = 1,
    int pageSize = 10,
    String? sortBy,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final ascending = sortBy == 'lowest';
    final orderColumn = switch (sortBy) {
      'highest' || 'lowest' => 'rating',
      _ => 'created_at',
    };

    final rows = await _client
        .from(AppConstants.reviewsTable)
        .select('*, user:profiles(id, full_name, avatar_url), review_images(*)')
        .eq('product_id', productId)
        .order(orderColumn, ascending: ascending)
        .range(from, to);

    return rows.map((row) => ReviewModel.fromJson(row)).toList();
  }

  Future<ReviewModel> createReview({
    required String userId,
    required String productId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1-5.');
    }

    final verified = await _hasDeliveredProduct(userId, productId);
    final row = await _client
        .from(AppConstants.reviewsTable)
        .insert({
          'user_id': userId,
          'product_id': productId,
          'order_id': orderId,
          'rating': rating,
          'comment': comment,
          'is_verified_purchase': verified,
        })
        .select()
        .single();

    await _refreshProductRating(productId);
    return ReviewModel.fromJson(row);
  }

  Future<List<String>> uploadReviewImages(
    String reviewId,
    List<File> images,
  ) async {
    final urls = <String>[];

    for (final image in images.take(5)) {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final path = 'reviews/$reviewId/$timestamp.jpg';
      await _client.storage
          .from(AppConstants.reviewImagesBucket)
          .upload(path, image, fileOptions: const FileOptions(upsert: true));
      final url = _client.storage
          .from(AppConstants.reviewImagesBucket)
          .getPublicUrl(path);
      urls.add(url);
    }

    if (urls.isNotEmpty) {
      await _client
          .from('review_images')
          .insert(
            urls
                .map((url) => {'review_id': reviewId, 'image_url': url})
                .toList(),
          );
    }

    return urls;
  }

  Future<ReviewSummary> getReviewSummary(String productId) async {
    final rows = await _client
        .from(AppConstants.reviewsTable)
        .select('rating')
        .eq('product_id', productId);

    if (rows.isEmpty) return ReviewSummary.empty();

    final distribution = {for (var star = 1; star <= 5; star++) star: 0};
    var totalRating = 0;
    for (final row in rows) {
      final rating = (row['rating'] as num?)?.toInt() ?? 0;
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
        totalRating += rating;
      }
    }

    return ReviewSummary(
      avgRating: totalRating / rows.length,
      totalReviews: rows.length,
      distribution: distribution,
    );
  }

  Future<bool> canUserReview(String userId, String productId) async {
    final existing = await _client
        .from(AppConstants.reviewsTable)
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    if (existing != null) return false;

    return _hasDeliveredProduct(userId, productId);
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    final rows = await _client
        .from(AppConstants.reviewsTable)
        .select('*, review_images(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((row) => ReviewModel.fromJson(row)).toList();
  }

  Future<({List<ReviewModel> items, int totalCount})> getAdminReviews({
    String? status,
    int? rating,
    String? search,
    String sortBy = 'created_at',
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    var query = _client
        .from(AppConstants.reviewsTable)
        .select('*, user:profiles(id, full_name, avatar_url), review_images(*)');

    if (status != null) {
      query = query.eq('status', status);
    }
    if (rating != null) {
      query = query.eq('rating', rating);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('comment', '%$search%');
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows =
        await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => ReviewModel.fromJson(row)).toList();

    var countQuery = _client.from(AppConstants.reviewsTable).select('id');
    if (status != null) {
      countQuery = countQuery.eq('status', status);
    }
    if (rating != null) {
      countQuery = countQuery.eq('rating', rating);
    }
    if (search != null && search.isNotEmpty) {
      countQuery = countQuery.ilike('comment', '%$search%');
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
  }

  Future<void> updateReviewStatus(String reviewId, String status) async {
    await _client
        .from(AppConstants.reviewsTable)
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reviewId);
  }

  Future<bool> _hasDeliveredProduct(String userId, String productId) async {
    final rows = await _client
        .from(AppConstants.ordersTable)
        .select('id, order_items!inner(product_id)')
        .eq('user_id', userId)
        .eq('status', 'delivered')
        .eq('order_items.product_id', productId)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<void> _refreshProductRating(String productId) async {
    final summary = await getReviewSummary(productId);
    await _client
        .from(AppConstants.productsTable)
        .update({
          'avg_rating': summary.avgRating,
          'average_rating': summary.avgRating,
          'total_reviews': summary.totalReviews,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }
}
