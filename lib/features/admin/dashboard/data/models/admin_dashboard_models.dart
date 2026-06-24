import '../../../../../core/models/model_converters.dart';

class DashboardStats {
  const DashboardStats({
    required this.todayOrders,
    required this.todayRevenue,
    required this.weekOrders,
    required this.weekRevenue,
    required this.monthOrders,
    required this.monthRevenue,
    required this.pendingOrders,
    required this.activeProducts,
    required this.dailyRevenue30Days,
    required this.ordersByStatus,
    required this.topShops,
    required this.monthlyUserGrowth,
  });

  final int todayOrders;
  final double todayRevenue;
  final int weekOrders;
  final double weekRevenue;
  final int monthOrders;
  final double monthRevenue;
  final int pendingOrders;
  final int activeProducts;

  final List<double> dailyRevenue30Days;
  final Map<String, int> ordersByStatus;
  final List<ShopRevenue> topShops;
  final List<MonthlyGrowth> monthlyUserGrowth;
}

class ShopRevenue {
  const ShopRevenue({
    required this.shopName,
    required this.revenue,
  });

  final String shopName;
  final double revenue;
}

class MonthlyGrowth {
  const MonthlyGrowth({
    required this.month,
    required this.count,
  });

  final String month;
  final int count;
}

class LowStockVariantModel {
  const LowStockVariantModel({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.stock,
    this.sku,
  });

  final String variantId;
  final String productName;
  final String? variantName;
  final String? sku;
  final int stock;

  factory LowStockVariantModel.fromJson(Map<String, dynamic> json) {
    return LowStockVariantModel(
      variantId: (json['variant_id'] ?? json['id']).toString(),
      productName: (json['product_name'] ??
              json['product']?['name'] ??
              json['name'] ??
              'Product')
          .toString(),
      variantName:
          (json['variant_name'] ?? json['name'] ?? json['option_display'])
              as String?,
      sku: json['sku'] as String?,
      stock: intFromJson(json['stock'] ?? json['quantity']) ?? 0,
    );
  }
}

class RevenueByCategoryModel {
  const RevenueByCategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
  });

  final String categoryId;
  final String categoryName;
  final double revenue;

  factory RevenueByCategoryModel.fromJson(Map<String, dynamic> json) {
    return RevenueByCategoryModel(
      categoryId: (json['category_id'] ?? '').toString(),
      categoryName: (json['category_name'] ?? json['name'] ?? 'Category')
          .toString(),
      revenue: doubleFromJson(json['revenue'] ?? json['total_revenue']) ?? 0,
    );
  }
}
