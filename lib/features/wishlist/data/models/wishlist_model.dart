import '../../../../core/models/model_converters.dart';

class WishlistItemModel {
  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final DateTime? createdAt;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      productId: json['product_id'].toString(),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'created_at': dateTimeToJson(createdAt),
  };
}
