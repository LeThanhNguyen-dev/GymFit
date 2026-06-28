import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../local/chat_local_database.dart';
import '../models/chat_contact_model.dart';
import '../models/chat_contact_query.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Bạn cần đăng nhập để sử dụng chat.');
    return userId;
  }

  /* ─── Conversations ─── */

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
        if (item.conversationId == conversationId) return item;
      }
      return null;
    });
  }

  /* ─── Messages with Optimistic UI ─── */

  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _client
        .from(AppConstants.chatMessagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => ChatMessageModel.fromJson({
                    ...row,
                    'local_id': row['id'].toString(),
                    'status': 'sent',
                  }))
              .toList(growable: false),
        );
  }

  Future<List<ChatMessageModel>> loadLocalMessages(String conversationId, {int limit = 50, DateTime? before}) async {
    return ChatLocalDatabase.getMessages(conversationId, limit: limit, beforeCreatedAt: before);
  }

  Future<List<ChatMessageModel>> loadPendingMessages() async {
    return ChatLocalDatabase.getPendingMessages();
  }

  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? messageType,
    String? mediaUrl,
    String? mediaPath,
    String? mediaThumb,
    int? mediaWidth,
    int? mediaHeight,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) async {
    final localId = const Uuid().v4();
    final optimistic = ChatMessageModel(
      id: localId,
      localId: localId,
      conversationId: conversationId,
      senderId: _currentUserId,
      content: content,
      messageType: messageType ?? 'text',
      mediaUrl: mediaUrl,
      mediaPath: mediaPath,
      mediaThumb: mediaThumb,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      fileName: fileName,
      fileSize: fileSize,
      replyToId: replyToId,
      status: 'sending',
    );

    await ChatLocalDatabase.insertMessage(optimistic);

    try {
      final response = await _client.from(AppConstants.chatMessagesTable).insert({
        'conversation_id': conversationId,
        'sender_id': _currentUserId,
        'content': content,
        if (messageType != null && messageType != 'text') 'message_type': messageType,
        'media_url': ?mediaUrl,
        'media_thumb': ?mediaThumb,
        'media_width': ?mediaWidth,
        'media_height': ?mediaHeight,
        'file_name': ?fileName,
        'file_size': ?fileSize,
        'reply_to_id': ?replyToId,
      }).select('id').single();

      final remoteId = response['id'].toString();
      await ChatLocalDatabase.updateMessageStatus(localId, conversationId, 'sent', remoteId: remoteId);

      // Client-side fallback update for preview in case DB trigger has not fired
      try {
        final preview = content.isNotEmpty
            ? content
            : (messageType == 'image' ? '[Hình ảnh]' : (messageType == 'file' ? '[Tập tin]' : ''));
        await _client.from(AppConstants.chatParticipantsTable).update({
          'last_message_preview': preview,
          'last_message_at': DateTime.now().toIso8601String(),
        }).eq('conversation_id', conversationId);
      } catch (_) {}

      return optimistic.copyWith(id: remoteId, status: 'sent');
    } catch (e) {
      await ChatLocalDatabase.updateMessageStatus(localId, conversationId, 'failed');
      rethrow;
    }
  }

  Future<void> syncPendingMessages() async {
    final pending = await ChatLocalDatabase.getPendingMessages();
    for (final msg in pending) {
      try {
        await _client.from(AppConstants.chatMessagesTable).insert({
          'conversation_id': msg.conversationId,
          'sender_id': msg.senderId,
          'content': msg.content,
          if (msg.messageType != 'text') 'message_type': msg.messageType,
          if (msg.mediaUrl != null) 'media_url': msg.mediaUrl,
          if (msg.mediaThumb != null) 'media_thumb': msg.mediaThumb,
          if (msg.replyToId != null) 'reply_to_id': msg.replyToId,
        }).select('id').single();
        await ChatLocalDatabase.updateMessageStatus(
          msg.localId, msg.conversationId, 'sent',
          remoteId: msg.localId,
        );
      } catch (_) {
        await ChatLocalDatabase.updateMessageStatus(msg.localId, msg.conversationId, 'failed');
      }
    }
  }

  /* ─── Image Upload ─── */

  Future<String> uploadImage(String conversationId, Uint8List bytes, {String? fileName}) async {
    final ext = fileName?.split('.').last ?? 'jpg';
    final path = 'chat/$conversationId/${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('chat-media').uploadBinary(path, bytes);
    final url = _client.storage.from('chat-media').getPublicUrl(path);
    return url;
  }


  /* ─── Reactions ─── */

  Future<void> toggleReaction(String conversationId, String messageId, String emoji) async {
    final current = await _client
        .from(AppConstants.chatMessagesTable)
        .select('reactions')
        .eq('id', messageId)
        .single();

    Map<String, int> reactions = {};
    if (current['reactions'] != null) {
      if (current['reactions'] is Map) {
        reactions = (current['reactions'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
      } else if (current['reactions'] is String) {
        try {
          reactions = Map<String, int>.from(
            jsonDecode(current['reactions'] as String).map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ),
          );
        } catch (_) {}
      }
    }

    final count = reactions[emoji] ?? 0;
    if (count > 0) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = 1;
    }

    await _client
        .from(AppConstants.chatMessagesTable)
        .update({'reactions': reactions})
        .eq('id', messageId);
  }

  /* ─── Typing Indicators via Broadcast API ─── */

  RealtimeChannel createTypingChannel(String conversationId) {
    return _client.channel(
      'typing:$conversationId',
      opts: const RealtimeChannelConfig(self: true),
    );
  }

  Future<void> sendTypingBroadcast(RealtimeChannel channel) async {
    await channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': _currentUserId},
    );
  }

  /* ─── Contacts ─── */

  Future<({List<ChatContactModel> items, int totalCount})> listContacts(ChatContactQuery query) async {
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

  /* ─── Conversation Management ─── */

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
    await ChatLocalDatabase.updateConversationUnread(conversationId, 0);
  }

  /* ─── Message Search ─── */

  Future<List<ChatMessageModel>> searchMessages(String conversationId, String query) async {
    return ChatLocalDatabase.searchMessages(conversationId, query);
  }

  /* ─── Delete ─── */

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _client.rpc('chat_delete_conversation', params: {'p_conversation_id': conversationId});
    } catch (_) {}
    await ChatLocalDatabase.deleteConversationMessages(conversationId);
  }
}
