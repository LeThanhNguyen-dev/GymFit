import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard_models.dart';
import '../models/inventory_log_model.dart';

class InventoryRepository {
  const InventoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<LowStockVariantModel>> getLowStockVariants() async {
    final rows = await _client
        .from('v_low_stock_variants')
        .select()
        .order('stock', ascending: true);

    return rows.map((row) => LowStockVariantModel.fromJson(row)).toList();
  }

  Future<List<InventoryLogModel>> getInventoryLogs(String variantId) async {
    final rows = await _client
        .from('inventory_logs')
        .select()
        .eq('variant_id', variantId)
        .order('created_at', ascending: false);

    return rows.map((row) => InventoryLogModel.fromJson(row)).toList();
  }

  Future<InventoryLogModel> createInventoryLog({
    required String variantId,
    required String changeType,
    required int quantityChange,
    String? note,
    String? createdBy,
  }) async {
    final variant = await _client
        .from('product_variants')
        .select('stock,quantity')
        .eq('id', variantId)
        .single();
    final before =
        (variant['stock'] ?? variant['quantity'] as num?)?.toInt() ?? 0;
    final after = before + quantityChange;

    final log = await _client
        .from('inventory_logs')
        .insert({
          'variant_id': variantId,
          'change_type': changeType,
          'quantity_change': quantityChange,
          'quantity_before': before,
          'quantity_after': after,
          'note': note,
          'created_by': createdBy,
        })
        .select()
        .single();

    await _client
        .from('product_variants')
        .update({
          'stock': after,
          'quantity': after,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', variantId);

    return InventoryLogModel.fromJson(log);
  }

  Future<List<RevenueByCategoryModel>> getRevenueByCategory() async {
    final rows = await _client
        .from('v_revenue_by_category')
        .select()
        .order('revenue', ascending: false);

    return rows.map((row) => RevenueByCategoryModel.fromJson(row)).toList();
  }
}
