class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }
}
