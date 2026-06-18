import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  const NotificationRepository(this._client);
  final SupabaseClient _client;

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => NotificationModel.fromJson(row)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }
}
