import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/chat_conversation_model.dart';
import '../../providers/chat_providers.dart';
import '../chat_scope.dart';

class ChatConversationsScreen extends ConsumerWidget {
  const ChatConversationsScreen({
    super.key,
    required this.scope,
  });

  final ChatScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(scope.title),
      ),
      body: conversationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              onStartChat: () => context.push(scope.newConversationPath),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatConversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ConversationTile(
                  item: item,
                  onTap: () => context.push(
                    scope.detailPath(item.conversationId),
                    extra: item,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải danh sách chat: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(scope.newConversationPath),
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Chat mới'),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.item,
    required this.onTap,
  });

  final ChatConversationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = item.lastMessagePreview?.trim().isNotEmpty == true
        ? item.lastMessagePreview!
        : 'Chưa có tin nhắn';

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          child: Text(item.initials),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(item.lastMessageAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (item.unreadCount > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isSameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    if (isSameDay) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Chưa có cuộc trò chuyện nào',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu chat realtime với admin, chủ shop hoặc khách hàng phù hợp với vai trò của bạn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Bắt đầu chat'),
            ),
          ],
        ),
      ),
    );
  }
}
