import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/local/chat_local_database.dart';
import '../../data/models/chat_contact_model.dart';
import '../../data/models/chat_conversation_model.dart';
import '../../data/models/chat_message_model.dart';
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
  final _imagePicker = ImagePicker();
  bool _isSending = false;
  bool _isMarkingRead = false;
  bool _isLoadingMore = false;
  String? _replyToId;
  String? _replyToContent;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _setupTypingPresence();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupTypingPresence() {
    ref.read(typingBroadcastProvider(widget.conversationId));
  }

  Future<void> _trackTyping() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final channel = ref.read(typingBroadcastProvider(widget.conversationId));
      await repo.sendTypingBroadcast(channel);
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    setState(() => _isLoadingMore = true);
    try {
      final messages = ref.read(chatMessagesProvider(widget.conversationId)).asData?.value ?? [];
      if (messages.isEmpty) return;
      final oldest = messages.first;
      final older = await ChatLocalDatabase.getMessages(
        widget.conversationId,
        limit: 30,
        beforeCreatedAt: oldest.createdAt,
      );
      if (older.isNotEmpty && mounted) {
        ref.invalidate(chatMessagesProvider(widget.conversationId));
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final participantAsync = ref.watch(
      chatConversationParticipantProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final isTyping = ref.watch(isSomeoneTypingProvider(widget.conversationId));
    final typingName = ref.watch(typingUserNameProvider(widget.conversationId));
    final connectionState = ref.watch(chatConnectionProvider);

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
              backgroundImage: _resolveImageProvider(participant?.peerAvatarUrl),
              child: participant?.peerAvatarUrl == null
                  ? Text(_initials(title))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _connectionBadge(connectionState),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_replyToId != null) _ReplyPreview(
            content: _replyToContent ?? '',
            onCancel: () => setState(() { _replyToId = null; _replyToContent = null; }),
          ),
          if (_pickedImage != null) _ImagePreview(
            file: _pickedImage!,
            onCancel: () => setState(() => _pickedImage = null),
            onSend: () => _sendImageMessage(),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _emptyState(context);
                }
                return _MessageListView(
                  messages: messages,
                  currentUserId: currentUserId ?? '',
                  scrollController: _scrollController,
                  isLoadingMore: _isLoadingMore,
                  onReactionTap: (msgId, emoji) {
                    ref.read(chatMessageActionsProvider).toggleReaction(widget.conversationId, msgId, emoji);
                  },
                  onReplyTap: (msg) {
                    setState(() {
                      _replyToId = msg.id;
                      _replyToContent = msg.content;
                    });
                  },
                  conversationId: widget.conversationId,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorState(context, error.toString()),
            ),
          ),
          if (isTyping)
            _TypingIndicator(name: typingName),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _connectionBadge(AsyncValue<ChatConnectionState> connState) {
    return connState.maybeWhen(
      data: (state) {
        IconData icon;
        Color color;
        String tooltip;
        switch (state) {
          case ChatConnectionState.connected:
            icon = Icons.wifi;
            color = Colors.green;
            tooltip = 'Đã kết nối';
          case ChatConnectionState.connecting:
            icon = Icons.wifi_find;
            color = Colors.orange;
            tooltip = 'Đang kết nối...';
          case ChatConnectionState.disconnected:
            icon = Icons.wifi_off;
            color = Colors.red;
            tooltip = 'Mất kết nối';
          case ChatConnectionState.error:
            icon = Icons.error_outline;
            color = Colors.red;
            tooltip = 'Lỗi kết nối';
        }
        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 18, color: color),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _emptyState(BuildContext context) {
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

  Widget _errorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Không thể tải tin nhắn', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(chatMessagesProvider(widget.conversationId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showAttachmentMenu,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => _trackTyping(),
                  onSubmitted: (_) => _sendTextMessage(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: _isSending ? null : _sendTextMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentButton(
                icon: Icons.photo_library,
                label: 'Thư viện',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _AttachmentButton(
                icon: Icons.camera_alt,
                label: 'Chụp ảnh',
                onTap: kIsWeb
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
      if (file != null) {
        setState(() => _pickedImage = file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref.read(chatMessageActionsProvider).send(
        conversationId: widget.conversationId,
        content: text,
        replyToId: _replyToId,
      );
      _messageController.clear();
      setState(() { _replyToId = null; _replyToContent = null; });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được tin nhắn: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImageMessage() async {
    if (_pickedImage == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final pickedImage = _pickedImage!;
      final url = await repo.uploadImage(
        widget.conversationId,
        await pickedImage.readAsBytes(),
        fileName: pickedImage.name,
      );
      await ref.read(chatMessageActionsProvider).send(
        conversationId: widget.conversationId,
        content: '',
        messageType: 'image',
        mediaUrl: url,
        mediaPath: kIsWeb ? null : pickedImage.path,
        replyToId: _replyToId,
      );
      setState(() {
        _pickedImage = null;
        _replyToId = null;
        _replyToContent = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được ảnh: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markRead() async {
    if (_isMarkingRead) return;
    _isMarkingRead = true;
    try {
      await ref.read(chatRepositoryProvider).markConversationRead(widget.conversationId);
    } catch (_) {
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

  ImageProvider? _resolveImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    final uri = Uri.tryParse(pathOrUrl);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (isNetwork) return NetworkImage(pathOrUrl);
    if (!kIsWeb) return FileImage(File(pathOrUrl));
    return null;
  }

  static String? _roleLabel(String? role) {
    switch (role) {
      case 'admin': return 'Quản trị viên';
      case 'storeowner': return 'Chủ shop';
      case 'customer': return 'Khách hàng';
      default: return null;
    }
  }
}

/* ─── Message List View (reverse: true — newest at bottom) ─── */

class _MessageListView extends StatelessWidget {
  const _MessageListView({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onReactionTap,
    required this.onReplyTap,
    required this.conversationId,
  });

  final List<ChatMessageModel> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final void Function(String messageId, String emoji) onReactionTap;
  final void Function(ChatMessageModel message) onReplyTap;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final sortedMessages = List<ChatMessageModel>.from(messages)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      reverse: true,
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: sortedMessages.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoadingMore && index == sortedMessages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final message = sortedMessages[index];
        final isMine = message.senderId == currentUserId;
        final showDateHeader = _showDateHeader(sortedMessages, index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) _DateHeader(dateTime: message.createdAt),
            _MessageBubble(
              message: message,
              isMine: isMine,
              onReactionTap: onReactionTap,
              onReplyTap: onReplyTap,
            ),
          ],
        );
      },
    );
  }

  bool _showDateHeader(List<ChatMessageModel> msgs, int index) {
    if (index == msgs.length - 1) return true;
    final current = msgs[index].createdAt;
    final next = msgs[index + 1].createdAt;
    return current.day != next.day ||
        current.month != next.month ||
        current.year != next.year;
  }
}

/* ─── Date Header ─── */

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.dateTime});
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isSameDay = now.year == local.year && now.month == local.month && now.day == local.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == local.year && yesterday.month == local.month && yesterday.day == local.day;

    String text;
    if (isSameDay) {
      text = 'Hôm nay';
    } else if (isYesterday) {
      text = 'Hôm qua';
    } else {
      text = '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)),
        ),
      ),
    );
  }
}

/* ─── Message Bubble (Messenger/Zalo style) ─── */

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onReactionTap,
    required this.onReplyTap,
  });

  final ChatMessageModel message;
  final bool isMine;
  final void Function(String messageId, String emoji) onReactionTap;
  final void Function(ChatMessageModel message) onReplyTap;

  @override
  Widget build(BuildContext context) {
    if (!isMine && message.isFailed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bubbleColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.replyToId != null && !isMine)
            _RepliedMessagePreview(
              replyToId: message.replyToId!,
              conversationId: message.conversationId,
              isMine: isMine,
            ),
          GestureDetector(
            onLongPress: () => _showMessageActions(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMine) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: _StatusIcon(status: message.status, isMine: isMine),
                  ),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: message.isFailed ? Colors.red.shade50 : bubbleColor,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMine ? const Radius.circular(4) : null,
                        bottomLeft: !isMine ? const Radius.circular(4) : null,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToId != null && isMine)
                          _RepliedMessagePreview(
                            replyToId: message.replyToId!,
                            conversationId: message.conversationId,
                            isMine: isMine,
                          ),
                        if (message.isImage && message.mediaUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _MediaContent(message: message),
                          ),
                        if (message.content.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: (message.reactions.isNotEmpty || message.isImage) ? 4 : 0,
                            ),
                            child: Text(
                              message.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: message.isFailed ? Colors.red : textColor,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: (message.isFailed ? Colors.red : textColor).withValues(alpha: 0.65),
                              ),
                            ),
                            if (message.reactions.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _ReactionStrip(reactions: message.reactions),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isMine) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: _StatusIcon(status: message.status, isMine: isMine),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(ctx);
                onReplyTap(message);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Cảm xúc'),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(context);
              },
            ),
            if (isMine && message.isFailed) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Gửi lại'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((emoji) => GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onReactionTap(message.id, emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            )).toList(),
          ),
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/* ─── Status Icon ─── */

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.isMine});
  final String status;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (!isMine) return const SizedBox(width: 16);

    IconData icon;
    Color color;
    switch (status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.grey;
      case 'sent':
        icon = Icons.check;
        color = Colors.grey.shade400;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey.shade500;
      case 'read':
        icon = Icons.done_all;
        color = Colors.blue.shade400;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
      default:
        icon = Icons.access_time;
        color = Colors.grey;
    }
    return Icon(icon, size: 14, color: color);
  }
}

/* ─── Media Content ─── */

class _MediaContent extends StatelessWidget {
  const _MediaContent({required this.message});
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl ?? '';
    final hasLocal = !kIsWeb && message.mediaPath != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasLocal
          ? Image.file(
              File(message.mediaPath!),
              fit: BoxFit.cover,
              width: 200,
              height: 200,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 64),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 200, height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 64),
            ),
    );
  }
}

/* ─── Reaction Strip ─── */

class _ReactionStrip extends StatelessWidget {
  const _ReactionStrip({required this.reactions});
  final Map<String, int> reactions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 1,
      children: reactions.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${e.key}${e.value > 1 ? ' ${e.value}' : ''}',
            style: const TextStyle(fontSize: 11)),
        );
      }).toList(),
    );
  }
}

/* ─── Replied Message Preview ─── */

class _RepliedMessagePreview extends ConsumerWidget {
  const _RepliedMessagePreview({
    required this.replyToId,
    required this.conversationId,
    required this.isMine,
  });

  final String replyToId;
  final String conversationId;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider(conversationId)).asData?.value ?? [];
    final replied = messages.where((m) => m.id == replyToId).firstOrNull;
    if (replied == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMine ? Colors.white24 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
      ),
      child: Text(
        replied.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: isMine ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

/* ─── Reply Preview ─── */

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
    required this.content,
    required this.onCancel,
  });
  final String content;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đang trả lời', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 2),
                Text(content, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

/* ─── Typing Indicator ─── */

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const _TypingDots(),
          const SizedBox(width: 8),
          Text(
            name != null ? '$name đang nhập...' : 'Đang nhập...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 200;
          final value = ((_controller.value * 1200 - delay) % 1200) / 1200;
          final scale = value < 0.3 ? 0.5 + value / 0.3 * 0.5 : (value < 0.6 ? 1.0 : 1.0 - (value - 0.6) / 0.4 * 0.5);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/* ─── Attachment Button ─── */

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              icon,
              color: onTap == null
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onTap == null ? Theme.of(context).disabledColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─── Image Preview ─── */

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.file,
    required this.onCancel,
    required this.onSend,
  });
  final XFile file;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 104,
              height: 104,
              child: FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  if (snapshot.hasError) {
                    return const Icon(Icons.image, size: 48);
                  }
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Gửi ảnh này?', style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
          IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}

/* ─── Build Helper ─── */

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
