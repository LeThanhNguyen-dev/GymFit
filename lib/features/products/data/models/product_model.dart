import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.description,
    this.imageUrl,
    this.iconUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'].toString(),
    parentId: json['parent_id'] as String?,
    name: json['name'].toString(),
    slug: json['slug'].toString(),
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    iconUrl: json['icon_url'] as String?,
    sortOrder: intFromJson(json['sort_order']) ?? 0,
    isActive: json['is_active'] as bool? ?? true,
    metadata: mapFromJson(json['metadata']),
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'name': name,
    'slug': slug,
    'description': description,
    'image_url': imageUrl,
    'icon_url': iconUrl,
    'sort_order': sortOrder,
    'is_active': isActive,
    'metadata': metadata,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}

class BrandModel {
  const BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.websiteUrl,
    this.country,
    this.isActive = true,
    this.isFeatured = false,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? websiteUrl;
  final String? country;
  final bool isActive;
  final bool isFeatured;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BrandModel.fromJson(Map<String, dynamic> json) => BrandModel(
    id: json['id'].toString(),
    name: json['name'].toString(),
    slug: json['slug'].toString(),
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    bannerUrl: json['banner_url'] as String?,
    websiteUrl: json['website_url'] as String?,
    country: json['country'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    isFeatured: json['is_featured'] as bool? ?? false,
    metadata: mapFromJson(json['metadata']),
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'logo_url': logoUrl,
    'banner_url': bannerUrl,
    'website_url': websiteUrl,
    'country': country,
    'is_active': isActive,
    'is_featured': isFeatured,
    'metadata': metadata,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.basePrice,
    this.sellerId,
    this.brandId,
    this.userId,
    this.sku,
    this.shortDescription,
    this.description,
    this.compareAtPrice,
    this.costPrice,
    this.status = ProductStatus.draft,
    this.isFeatured = false,
    this.isDigital = false,
    this.requiresShipping = true,
    this.weightGrams,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.tags = const [],
    this.attributes = const {},
    this.seoTitle,
    this.seoDescription,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalSold = 0,
    this.viewCount = 0,
    this.metadata = const {},
    this.category,
    this.brand,
    this.seller,
    this.images = const [],
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String? sellerId;
  final String? brandId;
  final String? userId;
  final String name;
  final String slug;
  final String? sku;
  final String? shortDescription;
  final String? description;
  final double basePrice;
  final double? compareAtPrice;
  final double? costPrice;
  final ProductStatus status;
  final bool isFeatured;
  final bool isDigital;
  final bool requiresShipping;
  final int? weightGrams;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final List<String> tags;
  final Map<String, dynamic> attributes;
  final String? seoTitle;
  final String? seoDescription;
  final double averageRating;
  final int totalReviews;
  final int totalSold;
  final int viewCount;
  final Map<String, dynamic> metadata;
  final CategoryModel? category;
  final BrandModel? brand;
  final SellerModel? seller;
  final List<ProductImageModel> images;
  final List<ProductVariantModel> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'].toString(),
    categoryId: json['category_id']?.toString() ?? '',
    sellerId: json['seller_id']?.toString(),
    brandId: json['brand_id'] as String?,
    userId: json['user_id'] as String?,
    name: json['name'].toString(),
    slug: json['slug']?.toString() ?? '',
    sku: json['sku'] as String?,
    shortDescription: json['short_description'] as String?,
    description: json['description'] as String?,
    basePrice: doubleFromJson(json['base_price'] ?? json['price']) ?? 0,
    compareAtPrice: doubleFromJson(json['compare_at_price']),
    costPrice: doubleFromJson(json['cost_price']),
    status: enumFromSnake(
      ProductStatus.values,
      json['status'],
      ProductStatus.draft,
    ),
    isFeatured: json['is_featured'] as bool? ?? false,
    isDigital: json['is_digital'] as bool? ?? false,
    requiresShipping: json['requires_shipping'] as bool? ?? true,
    weightGrams: intFromJson(json['weight_grams']),
    lengthCm: doubleFromJson(json['length_cm']),
    widthCm: doubleFromJson(json['width_cm']),
    heightCm: doubleFromJson(json['height_cm']),
    tags: stringListFromJson(json['tags']),
    attributes: mapFromJson(json['attributes']),
    seoTitle: json['seo_title'] as String?,
    seoDescription: json['seo_description'] as String?,
    averageRating:
        doubleFromJson(json['average_rating'] ?? json['avg_rating']) ?? 0,
    totalReviews: intFromJson(json['total_reviews']) ?? 0,
    totalSold: intFromJson(json['total_sold']) ?? 0,
    viewCount: intFromJson(json['view_count']) ?? 0,
    metadata: mapFromJson(json['metadata']),
    category: json['category'] is Map
        ? CategoryModel.fromJson(mapFromJson(json['category']))
        : null,
    brand: json['brand'] is Map
        ? BrandModel.fromJson(mapFromJson(json['brand']))
        : null,
    seller: json['seller'] is Map
        ? SellerModel.fromJson(mapFromJson(json['seller']))
        : null,
    images: mapListFromJson(
      json['images'],
    ).map(ProductImageModel.fromJson).toList(),
    variants: mapListFromJson(
      json['variants'],
    ).map(ProductVariantModel.fromJson).toList(),
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'seller_id': sellerId,
    'brand_id': brandId,
    'name': name,
    'slug': slug,
    'sku': sku,
    'short_description': shortDescription,
    'description': description,
    'base_price': basePrice,
    'compare_at_price': compareAtPrice,
    'cost_price': costPrice,
    'status': enumToSnake(status),
    'is_featured': isFeatured,
    'is_digital': isDigital,
    'requires_shipping': requiresShipping,
    'weight_grams': weightGrams,
    'length_cm': lengthCm,
    'width_cm': widthCm,
    'height_cm': heightCm,
    'tags': tags,
    'attributes': attributes,
    'seo_title': seoTitle,
    'seo_description': seoDescription,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'total_sold': totalSold,
    'view_count': viewCount,
    'metadata': metadata,
    'category': category?.toJson(),
    'brand': brand?.toJson(),
    'images': images.map((image) => image.toJson()).toList(),
    'variants': variants.map((variant) => variant.toJson()).toList(),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primaryImages = images.where((image) => image.isPrimary);
    return (primaryImages.isNotEmpty ? primaryImages.first : images.first).url;
  }
}

class ProductImageModel {
  const ProductImageModel({
    required this.id,
    required this.productId,
    required this.url,
    this.variantId,
    this.altText,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.width,
    this.height,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String? variantId;
  final String url;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;
  final int? width;
  final int? height;
  final DateTime? createdAt;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      variantId: json['variant_id'] as String?,
      url: (json['url'] ?? json['image_url']).toString(),
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: intFromJson(json['sort_order']) ?? 0,
      width: intFromJson(json['width']),
      height: intFromJson(json['height']),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'variant_id': variantId,
    'url': url,
    'alt_text': altText,
    'is_primary': isPrimary,
    'sort_order': sortOrder,
    'width': width,
    'height': height,
    'created_at': dateTimeToJson(createdAt),
  };
}

class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.productId,
    this.sku = '',
    required this.price,
    this.name,
    this.optionValues = const {},
    this.compareAtPrice,
    this.costPrice,
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.weightGrams,
    this.barcode,
    this.status = VariantStatus.active,
    this.imageUrl,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String sku;
  final String? name;
  final Map<String, dynamic> optionValues;
  final double price;
  final double? compareAtPrice;
  final double? costPrice;
  final int quantity;
  final int lowStockThreshold;
  final int? weightGrams;
  final String? barcode;
  final VariantStatus status;
  final String? imageUrl;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      sku: json['sku']?.toString() ?? '',
      name: (json['name'] ?? _variantNameFromJson(json)) as String?,
      optionValues: mapFromJson(json['option_values']).isNotEmpty
          ? mapFromJson(json['option_values'])
          : {
              if (json['size'] != null) 'Size': json['size'],
              if (json['color'] != null) 'Màu': json['color'],
            },
      price: doubleFromJson(json['price']) ?? 0,
      compareAtPrice: doubleFromJson(json['compare_at_price']),
      costPrice: doubleFromJson(json['cost_price']),
      quantity: intFromJson(json['quantity'] ?? json['stock']) ?? 0,
      lowStockThreshold: intFromJson(json['low_stock_threshold']) ?? 5,
      weightGrams: intFromJson(json['weight_grams']),
      barcode: json['barcode'] as String?,
      status: enumFromSnake(
        VariantStatus.values,
        json['status'],
        VariantStatus.active,
      ),
      imageUrl: json['image_url'] as String?,
      metadata: mapFromJson(json['metadata']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'sku': sku,
    'name': name,
    'option_values': optionValues,
    'price': price,
    'compare_at_price': compareAtPrice,
    'cost_price': costPrice,
    'quantity': quantity,
    'low_stock_threshold': lowStockThreshold,
    'weight_grams': weightGrams,
    'barcode': barcode,
    'status': enumToSnake(status),
    'image_url': imageUrl,
    'metadata': metadata,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  int get stock => quantity;
  String get optionDisplay => optionValues.entries
      .where(
        (entry) => entry.value != null && entry.value.toString().isNotEmpty,
      )
      .map((entry) => '${entry.key}: ${entry.value}')
      .join(', ');
}

String? _variantNameFromJson(Map<String, dynamic> json) {
  final values = [
    json['size']?.toString(),
    json['color']?.toString(),
  ].where((value) => value != null && value.isNotEmpty).cast<String>();
  return values.isEmpty ? null : values.join(' / ');
}


class SellerModel {
  const SellerModel({
    required this.id,
    this.fullName,
    this.email,
  });

  final String id;
  final String? fullName;
  final String? email;

  factory SellerModel.fromJson(Map<String, dynamic> json) => SellerModel(
    id: json['id'].toString(),
    fullName: json['full_name'] as String?,
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
  };
}

class InventoryLogModel {
  const InventoryLogModel({
    required this.id,
    required this.variantId,
    required this.action,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    this.performedBy,
    this.createdAt,
  });

  final String id;
  final String variantId;
  final InventoryAction action;
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final String? performedBy;
  final DateTime? createdAt;

  factory InventoryLogModel.fromJson(Map<String, dynamic> json) {
    return InventoryLogModel(
      id: json['id'].toString(),
      variantId: json['variant_id'].toString(),
      action: enumFromSnake(
        InventoryAction.values,
        json['action'],
        InventoryAction.adjustment,
      ),
      quantityChange: intFromJson(json['quantity_change']) ?? 0,
      quantityBefore: intFromJson(json['quantity_before']) ?? 0,
      quantityAfter: intFromJson(json['quantity_after']) ?? 0,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      note: json['note'] as String?,
      performedBy: json['performed_by'] as String?,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'variant_id': variantId,
    'action': enumToSnake(action),
    'quantity_change': quantityChange,
    'quantity_before': quantityBefore,
    'quantity_after': quantityAfter,
    'reference_type': referenceType,
    'reference_id': referenceId,
    'note': note,
    'performed_by': performedBy,
    'created_at': dateTimeToJson(createdAt),
  };
}
