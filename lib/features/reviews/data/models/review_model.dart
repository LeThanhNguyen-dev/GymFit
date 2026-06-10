import '../../../../core/models/model_converters.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.status = 'pending',
    this.isVerifiedPurchase = false,
    this.user,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String orderId;
  final int rating;
  final String? comment;
  final String status;
  final bool isVerifiedPurchase;
  final ReviewUserModel? user;
  final List<ReviewImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final relationUser = json['user'] ?? json['profile'] ?? json['profiles'];
    final relationImages = json['images'] ?? json['review_images'];

    return ReviewModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      productId: json['product_id'].toString(),
      orderId: json['order_id']?.toString() ?? '',
      rating: intFromJson(json['rating']) ?? 1,
      comment: (json['comment'] ?? json['body']) as String?,
      status: json['status']?.toString() ?? 'pending',
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
      user: relationUser is Map
          ? ReviewUserModel.fromJson(mapFromJson(relationUser))
          : null,
      images: mapListFromJson(
        relationImages,
      ).map(ReviewImageModel.fromJson).toList(),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'order_id': orderId,
    'rating': rating,
    'comment': comment,
    'status': status,
    'is_verified_purchase': isVerifiedPurchase,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}

class ReviewUserModel {
  const ReviewUserModel({required this.id, this.fullName, this.avatarUrl});

  final String id;
  final String? fullName;
  final String? avatarUrl;

  factory ReviewUserModel.fromJson(Map<String, dynamic> json) {
    return ReviewUserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      fullName:
          (json['full_name'] ?? json['name'] ?? json['display_name'])
              as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatar']) as String?,
    );
  }
}

class ReviewImageModel {
  const ReviewImageModel({
    required this.id,
    required this.reviewId,
    required this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String reviewId;
  final String imageUrl;
  final DateTime? createdAt;

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'].toString(),
      reviewId: json['review_id'].toString(),
      imageUrl: (json['image_url'] ?? json['url']).toString(),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'review_id': reviewId,
    'image_url': imageUrl,
    'created_at': dateTimeToJson(createdAt),
  };
}

class ReviewSummary {
  const ReviewSummary({
    required this.avgRating,
    required this.totalReviews,
    required this.distribution,
  });

  final double avgRating;
  final int totalReviews;
  final Map<int, int> distribution;

  factory ReviewSummary.empty() {
    return const ReviewSummary(
      avgRating: 0,
      totalReviews: 0,
      distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }
}
