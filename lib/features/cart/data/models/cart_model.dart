import '../../../../core/models/model_converters.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/data/models/product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.variantId,
    this.quantity = 1,
    this.product,
    this.variant,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String variantId;
  final int quantity;
  final ProductModel? product;
  final ProductVariantModel? variant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    productId: json['product_id'].toString(),
    variantId: json['variant_id'].toString(),
    quantity: intFromJson(json['quantity']) ?? 1,
    product: json['product'] is Map
        ? ProductModel.fromJson(mapFromJson(json['product']))
        : null,
    variant: json['variant'] is Map
        ? ProductVariantModel.fromJson(mapFromJson(json['variant']))
        : null,
    createdAt: dateTimeFromJson(json['created_at'] ?? json['added_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'variant_id': variantId,
    'quantity': quantity,
    'product': product?.toJson(),
    'variant': variant?.toJson(),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  double get itemTotal => (variant?.price ?? 0) * quantity;
  String get formattedTotal => formatCurrency(itemTotal);
  bool get isInStock => (variant?.stock ?? 0) >= quantity;
}

class CartSummary {
  const CartSummary({required this.subtotal, required this.itemCount});

  final double subtotal;
  final int itemCount;

  String get formattedSubtotal => formatCurrency(subtotal);
}
