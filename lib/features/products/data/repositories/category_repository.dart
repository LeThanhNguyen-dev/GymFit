import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class CategoryRepository {
  const CategoryRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'categories';

  Future<List<CategoryModel>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('sort_order', ascending: true);

    return rows.map((row) => CategoryModel.fromJson(row)).toList();
  }

  Future<CategoryModel?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : CategoryModel.fromJson(row);
  }

  Future<CategoryModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from(_table)
        .insert(data)
        .select()
        .single();

    return CategoryModel.fromJson(row);
  }

  Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from(_table)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return CategoryModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', id);
  }
}
