import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.orderItemId,
    this.title,
    this.body,
    this.status = ReviewStatus.pending,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.reply,
    this.repliedAt,
    this.repliedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String userId;
  final String? orderItemId;
  final int rating;
  final String? title;
  final String? body;
  final ReviewStatus status;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final String? reply;
  final DateTime? repliedAt;
  final String? repliedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'].toString(),
    productId: json['product_id'].toString(),
    userId: json['user_id'].toString(),
    orderItemId: json['order_item_id'] as String?,
    rating: intFromJson(json['rating']) ?? 1,
    title: json['title'] as String?,
    body: json['body'] as String?,
    status: enumFromSnake(
      ReviewStatus.values,
      json['status'],
      ReviewStatus.pending,
    ),
    isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
    helpfulCount: intFromJson(json['helpful_count']) ?? 0,
    reply: json['reply'] as String?,
    repliedAt: dateTimeFromJson(json['replied_at']),
    repliedBy: json['replied_by'] as String?,
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'user_id': userId,
    'order_item_id': orderItemId,
    'rating': rating,
    'title': title,
    'body': body,
    'status': enumToSnake(status),
    'is_verified_purchase': isVerifiedPurchase,
    'helpful_count': helpfulCount,
    'reply': reply,
    'replied_at': dateTimeToJson(repliedAt),
    'replied_by': repliedBy,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}

class ReviewImageModel {
  const ReviewImageModel({
    required this.id,
    required this.reviewId,
    required this.url,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String reviewId;
  final String url;
  final int sortOrder;
  final DateTime? createdAt;

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'].toString(),
      reviewId: json['review_id'].toString(),
      url: json['url'].toString(),
      sortOrder: intFromJson(json['sort_order']) ?? 0,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'review_id': reviewId,
    'url': url,
    'sort_order': sortOrder,
    'created_at': dateTimeToJson(createdAt),
  };
}
