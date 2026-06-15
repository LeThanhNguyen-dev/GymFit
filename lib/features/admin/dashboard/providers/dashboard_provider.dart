import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../orders/data/models/order_model.dart';
import '../data/models/admin_dashboard_models.dart';
import '../data/repositories/admin_order_repository.dart';
import '../data/repositories/inventory_repository.dart';

final adminOrderRepositoryProvider = Provider<AdminOrderRepository>((ref) {
  return AdminOrderRepository(ref.watch(supabaseClientProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(supabaseClientProvider));
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(adminOrderRepositoryProvider).getDashboardStats();
});

final lowStockProvider = FutureProvider<List<LowStockVariantModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getLowStockVariants();
});

final revenueByCategoryProvider = FutureProvider<List<RevenueByCategoryModel>>((
  ref,
) {
  return ref.watch(inventoryRepositoryProvider).getRevenueByCategory();
});

final recentOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(adminOrderRepositoryProvider).getRecentOrders();
});
