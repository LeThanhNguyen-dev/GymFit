import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class BrandRepository {
  const BrandRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'brands';

  Future<List<BrandModel>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('name', ascending: true);

    return rows.map((row) => BrandModel.fromJson(row)).toList();
  }

  Future<BrandModel?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : BrandModel.fromJson(row);
  }

  Future<BrandModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from(_table)
        .insert(data)
        .select()
        .single();

    return BrandModel.fromJson(row);
  }

  Future<BrandModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from(_table)
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return BrandModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', id);
  }
}
