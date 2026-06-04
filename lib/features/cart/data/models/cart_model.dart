import '../../../../core/models/model_converters.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.userId,
    required this.variantId,
    this.quantity = 1,
    this.addedAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String variantId;
  final int quantity;
  final DateTime? addedAt;
  final DateTime? updatedAt;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    variantId: json['variant_id'].toString(),
    quantity: intFromJson(json['quantity']) ?? 1,
    addedAt: dateTimeFromJson(json['added_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'variant_id': variantId,
    'quantity': quantity,
    'added_at': dateTimeToJson(addedAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
