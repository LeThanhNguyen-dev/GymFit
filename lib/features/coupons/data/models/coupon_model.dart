import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.discountValue,
    this.description,
    this.scope = VoucherScope.global,
    this.scopeRefId,
    this.maxDiscountAmount,
    this.minOrderAmount = 0,
    this.usageLimit,
    this.usageLimitPerUser = 1,
    this.usedCount = 0,
    this.isActive = true,
    this.startsAt,
    this.expiresAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final VoucherType type;
  final VoucherScope scope;
  final String? scopeRefId;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final int usageLimitPerUser;
  final int usedCount;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VoucherModel.fromJson(Map<String, dynamic> json) => VoucherModel(
    id: json['id'].toString(),
    code: json['code'].toString(),
    name: json['name'].toString(),
    description: json['description'] as String?,
    type: enumFromSnake(
      VoucherType.values,
      json['type'],
      VoucherType.percentage,
    ),
    scope: enumFromSnake(
      VoucherScope.values,
      json['scope'],
      VoucherScope.global,
    ),
    scopeRefId: json['scope_ref_id'] as String?,
    discountValue: doubleFromJson(json['discount_value']) ?? 0,
    maxDiscountAmount: doubleFromJson(json['max_discount_amount']),
    minOrderAmount: doubleFromJson(json['min_order_amount']) ?? 0,
    usageLimit: intFromJson(json['usage_limit']),
    usageLimitPerUser: intFromJson(json['usage_limit_per_user']) ?? 1,
    usedCount: intFromJson(json['used_count']) ?? 0,
    isActive: json['is_active'] as bool? ?? true,
    startsAt: dateTimeFromJson(json['starts_at']),
    expiresAt: dateTimeFromJson(json['expires_at']),
    createdBy: json['created_by'] as String?,
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'type': enumToSnake(type),
    'scope': enumToSnake(scope),
    'scope_ref_id': scopeRefId,
    'discount_value': discountValue,
    'max_discount_amount': maxDiscountAmount,
    'min_order_amount': minOrderAmount,
    'usage_limit': usageLimit,
    'usage_limit_per_user': usageLimitPerUser,
    'used_count': usedCount,
    'is_active': isActive,
    'starts_at': dateTimeToJson(startsAt),
    'expires_at': dateTimeToJson(expiresAt),
    'created_by': createdBy,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}

typedef CouponModel = VoucherModel;
