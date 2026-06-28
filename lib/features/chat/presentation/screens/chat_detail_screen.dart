import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/models/chat_contact_model.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../providers/chat_providers.dart';
import '../chat_scope.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.scope,
    required this.conversationId,
    this.fallbackName,
    this.fallbackRole,
  });

  final ChatScope scope;
  final String conversationId;
  final String? fallbackName;
  final String? fallbackRole;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _isMarkingRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final participantAsync = ref.watch(
      chatConversationParticipantProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));

    participantAsync.whenData((participant) {
      if (participant != null && participant.unreadCount > 0) {
        _markRead();
      }
    });

    final participant = participantAsync.asData?.value;
    final title = participant?.displayName ?? widget.fallbackName ?? 'Cuộc trò chuyện';
    final subtitle = participant?.roleDisplay ?? _roleLabel(widget.fallbackRole);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(_initials(title)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chưa có tin nhắn nào. Hãy gửi lời chào đầu tiên.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUserId;
                    return _MessageBubble(
                      content: message.content,
                      timestamp: message.createdAt,
                      isMine: isMine,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải tin nhắn: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            conversationId: widget.conversationId,
            content: text,
          );
      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được tin nhắn: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _markRead() async {
    if (_isMarkingRead) return;
    _isMarkingRead = true;
    try {
      await ref.read(chatRepositoryProvider).markConversationRead(widget.conversationId);
    } catch (_) {
      // Ignore read-mark failures to avoid blocking chat UI.
    } finally {
      _isMarkingRead = false;
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  static String _initials(String text) {
    if (text.isEmpty) return '?';
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return text[0].toUpperCase();
  }

  static String? _roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'storeowner':
        return 'Chủ shop';
      case 'customer':
        return 'Khách hàng';
      default:
        return null;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.content,
    required this.timestamp,
    required this.isMine,
  });

  final String content;
  final DateTime timestamp;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

ChatDetailScreen buildChatDetailScreen({
  required ChatScope scope,
  required String conversationId,
  Object? extra,
}) {
  String? fallbackName;
  String? fallbackRole;

  if (extra is ChatConversationModel) {
    fallbackName = extra.displayName;
    fallbackRole = extra.peerRole;
  } else if (extra is ChatContactModel) {
    fallbackName = extra.fullName;
    fallbackRole = extra.role;
  }

  return ChatDetailScreen(
    scope: scope,
    conversationId: conversationId,
    fallbackName: fallbackName,
    fallbackRole: fallbackRole,
  );
}
