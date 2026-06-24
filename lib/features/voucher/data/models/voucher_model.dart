import '../../../../core/models/model_converters.dart';
import '../../../../core/utils/currency_formatter.dart';

class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.maxDiscountAmount,
    this.usageLimit,
    this.scope = 'admin',
    this.sellerId,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final String scope;
  final String? sellerId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return VoucherModel(
      id: json['id'].toString(),
      code: json['code'].toString(),
      description: json['description'] as String?,
      discountType: json['discount_type'].toString(),
      discountValue: doubleFromJson(json['discount_value']) ?? 0,
      minOrderAmount: doubleFromJson(json['min_order_amount']) ?? 0,
      maxDiscountAmount: doubleFromJson(json['max_discount_amount']),
      usageLimit: intFromJson(json['usage_limit']),
      usedCount: intFromJson(json['used_count']) ?? 0,
      scope: json['scope']?.toString() ?? 'admin',
      sellerId: json['seller_id']?.toString(),
      startDate: dateTimeFromJson(json['start_date']) ?? now,
      endDate: dateTimeFromJson(json['end_date']) ?? now,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: dateTimeFromJson(json['created_at']) ?? now,
      updatedAt: dateTimeFromJson(json['updated_at']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'discount_type': discountType,
    'discount_value': discountValue,
    'min_order_amount': minOrderAmount,
    'max_discount_amount': maxDiscountAmount,
    'usage_limit': usageLimit,
    'used_count': usedCount,
    'scope': scope,
    'seller_id': sellerId,
    'start_date': dateTimeToJson(startDate),
    'end_date': dateTimeToJson(endDate),
    'is_active': isActive,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUsageLimitReached =>
      usageLimit != null && usedCount >= usageLimit!;

  bool get canUse => isValid && !isUsageLimitReached;
  bool get isAdminVoucher => scope == 'admin';
  bool get isShopVoucher => scope == 'shop';

  String get discountDisplay {
    if (discountType == 'percentage') return '${discountValue.toInt()}%';
    return formatCurrency(discountValue);
  }

  double calculateDiscount(double orderAmount) {
    if (!canUse || orderAmount < minOrderAmount) return 0;
    final discount = discountType == 'percentage'
        ? orderAmount * (discountValue / 100)
        : discountValue;
    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      return maxDiscountAmount!;
    }
    return discount;
  }
}

class VoucherValidationResult {
  const VoucherValidationResult({
    required this.voucher,
    required this.discountAmount,
  });

  final VoucherModel voucher;
  final double discountAmount;
}
