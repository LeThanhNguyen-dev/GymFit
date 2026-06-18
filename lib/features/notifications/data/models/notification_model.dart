import 'package:flutter/material.dart';
import '../../../../core/models/model_converters.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    type: json['type']?.toString() ?? 'system',
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    isRead: json['is_read'] as bool? ?? false,
    data: json['data'] as Map<String, dynamic>?,
    createdAt: dateTimeFromJson(json['created_at']) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'title': title,
    'message': message,
    'is_read': isRead,
    'data': data,
    'created_at': dateTimeToJson(createdAt),
  };

  IconData get icon {
    switch (type) {
      case 'order_confirmed': return Icons.check_circle;
      case 'order_shipped': return Icons.local_shipping;
      case 'promotion': return Icons.local_offer;
      case 'payment_success': return Icons.credit_card;
      case 'back_in_stock': return Icons.inventory_2;
      default: return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'order_confirmed': return AppColors.success;
      case 'order_shipped': return AppColors.secondary;
      case 'promotion': return AppColors.primary;
      case 'payment_success': return AppColors.success;
      case 'back_in_stock': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  String get timestamp {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
