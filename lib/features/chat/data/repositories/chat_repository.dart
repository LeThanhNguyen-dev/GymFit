import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/chat_contact_model.dart';
import '../models/chat_contact_query.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  const ChatRepository(this._client);

  final SupabaseClient _client;

  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Bạn cần đăng nhập để sử dụng chat.');
    }
    return userId;
  }

  Stream<List<ChatConversationModel>> watchConversations() {
    final userId = _currentUserId;
    return _client
        .from(AppConstants.chatParticipantsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('last_message_at', ascending: false)
        .map(
          (rows) => rows
            ..sort((a, b) {
              final aTime = DateTime.tryParse(a['last_message_at']?.toString() ?? '');
              final bTime = DateTime.tryParse(b['last_message_at']?.toString() ?? '');
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            }),
        )
        .map(
          (rows) => rows
              .map((row) => ChatConversationModel.fromJson(row))
              .toList(growable: false),
        );
  }

  Stream<ChatConversationModel?> watchConversationParticipant(String conversationId) {
    return watchConversations().map((items) {
      for (final item in items) {
        if (item.conversationId == conversationId) {
          return item;
        }
      }
      return null;
    });
  }

  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _client
        .from(AppConstants.chatMessagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map(
          (rows) {
            final items = rows
                .map((row) => ChatMessageModel.fromJson(row))
                .toList();
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return items;
          },
        );
  }

  Future<({List<ChatContactModel> items, int totalCount})> listContacts(
    ChatContactQuery query,
  ) async {
    final result = await _client.rpc(
      'chat_list_contacts',
      params: {
        'search_text': query.search?.trim().isEmpty == true ? null : query.search?.trim(),
        'role_filter': query.roleFilter,
        'page_num': query.page,
        'page_size': query.pageSize,
      },
    );

    final data = Map<String, dynamic>.from(result as Map);
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((row) => ChatContactModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final totalCount = (data['totalCount'] as num?)?.toInt() ?? items.length;
    return (items: items, totalCount: totalCount);
  }

  Future<String> createOrGetDirectConversation(String targetUserId) async {
    final result = await _client.rpc(
      'chat_create_or_get_direct_conversation',
      params: {'p_target_user_id': targetUserId},
    );
    return result.toString();
  }

  Future<void> markConversationRead(String conversationId) async {
    await _client.rpc(
      'chat_mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    await _client.from(AppConstants.chatMessagesTable).insert({
      'conversation_id': conversationId,
      'sender_id': _currentUserId,
      'content': trimmed,
    });
  }
}
