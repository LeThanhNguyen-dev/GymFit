import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabaseService {
  const SupabaseDatabaseService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder table(String tableName) => _client.from(tableName);

  Future<List<Map<String, dynamic>>> select(
    String tableName, {
    String columns = '*',
  }) async {
    final rows = await _client.from(tableName).select(columns);
    return rows.map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> insert(
    String tableName,
    Map<String, dynamic> values,
  ) async {
    final row = await _client.from(tableName).insert(values).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateById(
    String tableName,
    Object id,
    Map<String, dynamic> values,
  ) async {
    final row = await _client
        .from(tableName)
        .update(values)
        .eq('id', id)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<void> deleteById(String tableName, Object id) async {
    await _client.from(tableName).delete().eq('id', id);
  }
}
