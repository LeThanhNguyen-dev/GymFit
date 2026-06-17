import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/error_handler.dart';
import '../models/admin_user_model.dart';

class AdminUserRepository {
  AdminUserRepository(this._client);

  final SupabaseClient _client;

  Future<({List<AdminUserModel> items, int totalCount})> getAllUsers({
    String? search,
    String? role,
    String? sellerStatus,
    bool? banned,
    String? sortBy = 'created_at',
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      dynamic query = _client.from('profiles').select();

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$search%,email.ilike.%$search%',
        );
      }
      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }
      if (sellerStatus != null && sellerStatus.isNotEmpty) {
        query = query.eq('seller_status', sellerStatus);
      }
      if (banned != null) {
        query = query.eq('is_banned', banned);
      }

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      query = query.order(sortBy!, ascending: ascending).range(from, to);

      final rows = List<Map<String, dynamic>>.from(await query);
      final items = rows.map((row) => AdminUserModel.fromJson(row)).toList();

      var countQuery = _client.from('profiles').select('id');
      if (search != null && search.isNotEmpty) {
        countQuery = countQuery.or(
          'full_name.ilike.%$search%,email.ilike.%$search%',
        );
      }
      if (role != null && role.isNotEmpty) {
        countQuery = countQuery.eq('role', role);
      }
      if (sellerStatus != null && sellerStatus.isNotEmpty) {
        countQuery = countQuery.eq('seller_status', sellerStatus);
      }
      if (banned != null) {
        countQuery = countQuery.eq('is_banned', banned);
      }
      final countResult = List<Map<String, dynamic>>.from(await countQuery);
      final totalCount = countResult.length;

      return (items: items, totalCount: totalCount);
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<AdminUserModel> getUserById(String userId) async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .limit(1);

      if (rows.isEmpty) throw Exception('User not found');
      return AdminUserModel.fromJson(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _client
          .from('profiles')
          .update({'role': role, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> toggleBan(String userId, {bool banned = true, String? reason}) async {
    try {
      final data = <String, dynamic>{
        'is_banned': banned,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (banned) {
        data['ban_reason'] = reason;
        data['banned_at'] = DateTime.now().toUtc().toIso8601String();
      } else {
        data['ban_reason'] = null;
        data['banned_at'] = null;
      }
      await _client.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> updateSellerStatus(String userId, String status) async {
    try {
      await _client.from('profiles').update({
        'seller_status': status,
        if (status == 'approved' || status == 'rejected')
          'role': 'seller',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }
}
