import 'dart:convert';

import 'package:uuid/uuid.dart';

class ChatMessageModel {
  ChatMessageModel({
    String? id,
    String? localId,
    required this.conversationId,
    required this.senderId,
    this.content = '',
    this.messageType = 'text',
    this.mediaUrl,
    this.mediaPath,
    this.mediaThumb,
    this.mediaWidth,
    this.mediaHeight,
    this.fileName,
    this.fileSize,
    Map<String, int>? reactions,
    this.replyToId,
    this.status = 'sending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? localId ?? const Uuid().v4(),
        localId = localId ?? const Uuid().v4(),
        reactions = reactions ?? const {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String localId;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final String? mediaUrl;
  final String? mediaPath;
  final String? mediaThumb;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? fileName;
  final int? fileSize;
  final Map<String, int> reactions;
  final String? replyToId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isMine => true;
  bool get isPending => status == 'pending';
  bool get isSending => status == 'sending';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';
  bool get isFailed => status == 'failed';
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get hasMedia => mediaUrl != null || mediaPath != null;

  ChatMessageModel copyWith({
    String? id,
    String? localId,
    String? conversationId,
    String? senderId,
    String? content,
    String? messageType,
    String? mediaUrl,
    String? mediaPath,
    String? mediaThumb,
    int? mediaWidth,
    int? mediaHeight,
    String? fileName,
    int? fileSize,
    Map<String, int>? reactions,
    String? replyToId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearMedia = false,
    bool clearReactions = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: clearMedia ? null : (mediaUrl ?? this.mediaUrl),
      mediaPath: clearMedia ? null : (mediaPath ?? this.mediaPath),
      mediaThumb: clearMedia ? null : (mediaThumb ?? this.mediaThumb),
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      fileName: clearMedia ? null : (fileName ?? this.fileName),
      fileSize: fileSize ?? this.fileSize,
      reactions: clearReactions ? const {} : (reactions ?? this.reactions),
      replyToId: replyToId ?? this.replyToId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> reactions = {};
    if (json['reactions'] != null) {
      try {
        if (json['reactions'] is Map) {
          reactions = (json['reactions'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v is int ? v : (v as num).toInt())),
          );
        } else if (json['reactions'] is String) {
          final decoded = jsonDecode(json['reactions'] as String);
          if (decoded is Map) {
            reactions = decoded.map(
              (k, v) => MapEntry(k.toString(), (v is int ? v : (v as num).toInt())),
            );
          }
        }
      } catch (_) {}
    }

    return ChatMessageModel(
      id: json['id']?.toString(),
      localId: json['local_id']?.toString(),
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString(),
      mediaPath: json['media_path']?.toString(),
      mediaThumb: json['media_thumb']?.toString(),
      mediaWidth: (json['media_width'] as num?)?.toInt(),
      mediaHeight: (json['media_height'] as num?)?.toInt(),
      fileName: json['file_name']?.toString(),
      fileSize: (json['file_size'] as num?)?.toInt(),
      reactions: reactions,
      replyToId: json['reply_to_id']?.toString(),
      status: json['status']?.toString() ?? 'sent',
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'local_id': localId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'media_url': mediaUrl,
      'media_path': mediaPath,
      'media_thumb': mediaThumb,
      'media_width': mediaWidth,
      'media_height': mediaHeight,
      'file_name': fileName,
      'file_size': fileSize,
      'reactions': reactions,
      'reply_to_id': replyToId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
