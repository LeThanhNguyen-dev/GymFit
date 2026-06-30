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
      final result = await _client.rpc('admin_list_profiles', params: {
        if (search != null && search.isNotEmpty) 'search_text': search,
        'role_filter': ?role,
        'seller_status_filter': ?sellerStatus,
        'banned_filter': ?banned,
        'sort_col': sortBy,
        'sort_asc': ascending,
        'page_num': page,
        'page_size': pageSize,
      });

      final data = Map<String, dynamic>.from(result);
      final items = (data['items'] as List)
          .map((row) => AdminUserModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      final totalCount = data['totalCount'] as int;

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
      await _client.rpc('admin_update_user_role', params: {
        'target_id': userId,
        'new_role': role,
      });
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> toggleBan(String userId, {bool banned = true, String? reason}) async {
    try {
      await _client.rpc('admin_toggle_ban', params: {
        'target_id': userId,
        'set_banned': banned,
        'reason_text': ?reason,
      });
    } catch (e) {
      throw handleSupabaseError(e);
    }
  }

  Future<void> updateSellerStatus(String userId, String status) async {
    try {
      await _client.rpc('admin_update_seller_status', params: {
        'target_id': userId,
        'new_status': status,
      });
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
