import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/local/chat_local_database.dart';
import '../data/models/chat_contact_model.dart';
import '../data/models/chat_contact_query.dart';
import '../data/models/chat_conversation_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository.dart';

/* ─── Repository ─── */

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

/* ─── Conversations ─── */

final chatConversationsProvider =
    StreamProvider.autoDispose<List<ChatConversationModel>>((ref) {
  return ref.watch(chatRepositoryProvider).watchConversations();
});

final chatConversationParticipantProvider =
    StreamProvider.autoDispose.family<ChatConversationModel?, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchConversationParticipant(conversationId);
});

/* ─── Messages Stream ─── */

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessageModel>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

/* ─── Message Actions ─── */

class ChatMessageActions {
  const ChatMessageActions(this._ref);

  final Ref _ref;

  Future<ChatMessageModel> send({
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
    final repo = _ref.read(chatRepositoryProvider);
    try {
      return await repo.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
        mediaPath: mediaPath,
        mediaThumb: mediaThumb,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        fileName: fileName,
        fileSize: fileSize,
        replyToId: replyToId,
      );
    } catch (e) {
      _ref.invalidate(chatMessagesProvider(conversationId));
      rethrow;
    }
  }

  Future<void> retry(ChatMessageModel message) async {
    _ref.invalidate(chatMessagesProvider(message.conversationId));
    final repo = _ref.read(chatRepositoryProvider);
    await repo.sendMessage(
      conversationId: message.conversationId,
      content: message.content,
      messageType: message.messageType,
      mediaUrl: message.mediaUrl,
      mediaPath: message.mediaPath,
      replyToId: message.replyToId,
    );
  }

  Future<void> toggleReaction(String conversationId, String messageId, String emoji) async {
    final repo = _ref.read(chatRepositoryProvider);
    try {
      await repo.toggleReaction(conversationId, messageId, emoji);
    } catch (_) {}
  }
}

final chatMessageActionsProvider = Provider<ChatMessageActions>((ref) {
  return ChatMessageActions(ref);
});

/* ─── Typing Indicators (via Broadcast API) ─── */

final typingBroadcastProvider = Provider.autoDispose.family<RealtimeChannel, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  final channel = repo.createTypingChannel(conversationId);

  channel.onBroadcast(
    event: 'typing',
    callback: (payload) {},
  );
  channel.subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
  });
  return channel;
});

final chatTypingUsersProvider = StreamProvider.autoDispose.family<Set<String>, String>((ref, conversationId) {
  final channel = ref.watch(typingBroadcastProvider(conversationId));
  final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  final controller = StreamController<Set<String>>.broadcast();
  final timers = <String, Timer>{};

  void clearUser(String userId) {
    timers.remove(userId);
    final remaining = timers.keys.toSet();
    controller.add(remaining);
  }

  channel.onBroadcast(
    event: 'typing',
    callback: (payload) {
      final userId = payload['user_id']?.toString();
      if (userId == null || userId == currentUserId) return;
      timers[userId]?.cancel();
      timers[userId] = Timer(const Duration(seconds: 3), () => clearUser(userId));
      controller.add({userId});
    },
  );

  ref.onDispose(() {
    for (final t in timers.values) { t.cancel(); }
    controller.close();
  });

  return controller.stream;
});

final isSomeoneTypingProvider = Provider.autoDispose.family<bool, String>((ref, conversationId) {
  final typing = ref.watch(chatTypingUsersProvider(conversationId));
  return typing.maybeWhen(
    data: (users) => users.isNotEmpty,
    orElse: () => false,
  );
});

final typingUserNameProvider = Provider.autoDispose.family<String?, String>((ref, conversationId) {
  final conv = ref.watch(chatConversationParticipantProvider(conversationId));
  final typing = ref.watch(chatTypingUsersProvider(conversationId));
  return typing.maybeWhen(
    data: (users) {
      if (users.isEmpty) return null;
      return conv.maybeWhen(
        data: (p) => p?.peerName,
        orElse: () => null,
      );
    },
    orElse: () => null,
  );
});

/* ─── Connection State ─── */

enum ChatConnectionState { connected, connecting, disconnected, error }

final chatConnectionProvider = StreamProvider.autoDispose<ChatConnectionState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<ChatConnectionState>.broadcast();

  void emit(ChatConnectionState state) {
    if (!controller.isClosed) controller.add(state);
  }

  emit(ChatConnectionState.connecting);

  final subscription = client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      emit(ChatConnectionState.connected);
    } else if (data.event == AuthChangeEvent.signedOut) {
      emit(ChatConnectionState.disconnected);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/* ─── Contacts ─── */

final chatContactsProvider = FutureProvider.autoDispose
    .family<({List<ChatContactModel> items, int totalCount}), ChatContactQuery>((ref, query) {
  return ref.watch(chatRepositoryProvider).listContacts(query);
});

/* ─── Unread Count ─── */

final chatUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final conversations = ref.watch(chatConversationsProvider);
  return conversations.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.unreadCount),
    orElse: () => 0,
  );
});

/* ─── Message Search ─── */

final chatSearchProvider = FutureProvider.autoDispose.family<List<ChatMessageModel>, ({String conversationId, String query})>(
  (ref, params) {
    return ref.read(chatRepositoryProvider).searchMessages(params.conversationId, params.query);
  },
);

final lastMessagePreviewProvider = FutureProvider.autoDispose.family<String?, String>((ref, conversationId) async {
  final msgs = await ChatLocalDatabase.getMessages(conversationId, limit: 1);
  if (msgs.isNotEmpty) {
    final last = msgs.first;
    if (last.messageType == 'image') return '[Hình ảnh]';
    if (last.messageType == 'file') return '[Tập tin]';
    return last.content;
  }
  return null;
});
