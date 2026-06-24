class ChatConversationModel {
  const ChatConversationModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.peerUserId,
    required this.peerName,
    required this.peerEmail,
    this.peerAvatarUrl,
    required this.peerRole,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String conversationId;
  final String userId;
  final String peerUserId;
  final String peerName;
  final String peerEmail;
  final String? peerAvatarUrl;
  final String peerRole;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  String get displayName => peerName.isNotEmpty ? peerName : peerEmail;

  String get roleDisplay {
    switch (peerRole) {
      case 'admin':
        return 'Quản trị viên';
      case 'storeowner':
        return 'Chủ shop';
      default:
        return 'Khách hàng';
    }
  }

  String get initials {
    final source = displayName;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      userId: json['user_id'].toString(),
      peerUserId: json['peer_user_id'].toString(),
      peerName: json['peer_name']?.toString() ?? '',
      peerEmail: json['peer_email']?.toString() ?? '',
      peerAvatarUrl: json['peer_avatar_url'] as String?,
      peerRole: json['peer_role']?.toString() ?? 'customer',
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.tryParse(json['last_message_at'].toString()),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
