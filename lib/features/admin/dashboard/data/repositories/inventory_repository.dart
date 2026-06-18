import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard_models.dart';
import '../models/inventory_log_model.dart';

class InventoryRepository {
  const InventoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<LowStockVariantModel>> getLowStockVariants() async {
    const select =
        'id, product_id, sku, name, quantity, low_stock_threshold, option_values, product:products(id, name)';
    final rows = await _client
        .from('product_variants')
        .select(select)
        .lte('quantity', 5)
        .order('quantity', ascending: true);

    return rows.map((row) => LowStockVariantModel.fromJson(row)).toList();
  }

  static const String _variantSelect =
      'id, product_id, sku, name, quantity, low_stock_threshold, option_values, product:products(id, name)';

  Future<({List<LowStockVariantModel> items, int totalCount})> getInventoryVariants({
    String? search,
    String? stockLevel,
    String? categoryId,
    String sortBy = 'quantity',
    bool ascending = true,
    int page = 1,
    int pageSize = 20,
  }) async {
    var query = _client.from('product_variants').select(_variantSelect);

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'name.ilike.%$search%,sku.ilike.%$search%',
      );
    }
    if (stockLevel == 'low') {
      query = query.lte('quantity', 5);
    } else if (stockLevel == 'out') {
      query = query.eq('quantity', 0);
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final rows = await query.order(sortBy, ascending: ascending).range(from, to);
    final items = rows.map((row) => LowStockVariantModel.fromJson(row)).toList();

    var countQuery = _client.from('product_variants').select('id');
    if (search != null && search.isNotEmpty) {
      countQuery = countQuery.or(
        'name.ilike.%$search%,sku.ilike.%$search%',
      );
    }
    if (stockLevel == 'low') {
      countQuery = countQuery.lte('quantity', 5);
    } else if (stockLevel == 'out') {
      countQuery = countQuery.eq('quantity', 0);
    }
    final countResult = List<Map<String, dynamic>>.from(await countQuery);
    final totalCount = countResult.length;

    return (items: items, totalCount: totalCount);
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
        .select('quantity')
        .eq('id', variantId)
        .single();
    final before = (variant['quantity'] as num?)?.toInt() ?? 0;
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
        .order('total_revenue', ascending: false);

    return rows.map((row) => RevenueByCategoryModel.fromJson(row)).toList();
  }
}
