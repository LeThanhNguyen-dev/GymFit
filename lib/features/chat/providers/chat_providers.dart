import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/chat_contact_model.dart';
import '../data/models/chat_contact_query.dart';
import '../data/models/chat_conversation_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final chatConversationsProvider =
    StreamProvider.autoDispose<List<ChatConversationModel>>((ref) {
  return ref.watch(chatRepositoryProvider).watchConversations();
});

final chatConversationParticipantProvider =
    StreamProvider.autoDispose.family<ChatConversationModel?, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchConversationParticipant(conversationId);
});

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessageModel>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final chatContactsProvider = FutureProvider.autoDispose
    .family<({List<ChatContactModel> items, int totalCount}), ChatContactQuery>((ref, query) {
  return ref.watch(chatRepositoryProvider).listContacts(query);
});

final chatUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final conversations = ref.watch(chatConversationsProvider);
  return conversations.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.unreadCount),
    orElse: () => 0,
  );
});
