import 'package:flutter/material.dart';

import '../../../../core/models/model_converters.dart';

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    this.orderId,
    this.status = 'open',
    this.priority = 'normal',
    this.adminReply,
    this.repliedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? orderId;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusDisplay => switch (status) {
    'in_progress' => 'In progress',
    'resolved' => 'Resolved',
    'closed' => 'Closed',
    _ => 'Open',
  };

  Color get statusColor => switch (status) {
    'in_progress' => Colors.blue,
    'resolved' => Colors.green,
    'closed' => Colors.grey,
    _ => Colors.orange,
  };

  String get priorityDisplay => switch (priority) {
    'low' => 'Low',
    'high' => 'High',
    'urgent' => 'Urgent',
    _ => 'Normal',
  };

  Color get priorityColor => switch (priority) {
    'low' => Colors.grey,
    'high' => Colors.deepOrange,
    'urgent' => Colors.red,
    _ => Colors.indigo,
  };

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      orderId: json['order_id'] as String?,
      subject: json['subject'].toString(),
      description: json['description'].toString(),
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'normal',
      adminReply: (json['admin_reply'] ?? json['resolution_note']) as String?,
      repliedAt: dateTimeFromJson(
        json['replied_at'] ?? json['first_response_at'],
      ),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'order_id': orderId,
    'subject': subject,
    'description': description,
    'status': status,
    'priority': priority,
    'admin_reply': adminReply,
    'replied_at': dateTimeToJson(repliedAt),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  SupportTicketModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    String? subject,
    String? description,
    String? status,
    String? priority,
    String? adminReply,
    DateTime? repliedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
