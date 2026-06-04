import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.category,
    required this.subject,
    required this.description,
    this.orderId,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.attachments = const [],
    this.assignedTo,
    this.resolvedAt,
    this.firstResponseAt,
    this.closedAt,
    this.resolutionNote,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ticketNumber;
  final String userId;
  final String? orderId;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String subject;
  final String description;
  final List<String> attachments;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final DateTime? firstResponseAt;
  final DateTime? closedAt;
  final String? resolutionNote;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'].toString(),
      ticketNumber: json['ticket_number'].toString(),
      userId: json['user_id'].toString(),
      orderId: json['order_id'] as String?,
      category: enumFromSnake(
        TicketCategory.values,
        json['category'],
        TicketCategory.other,
      ),
      priority: enumFromSnake(
        TicketPriority.values,
        json['priority'],
        TicketPriority.medium,
      ),
      status: enumFromSnake(
        TicketStatus.values,
        json['status'],
        TicketStatus.open,
      ),
      subject: json['subject'].toString(),
      description: json['description'].toString(),
      attachments: stringListFromJson(json['attachments']),
      assignedTo: json['assigned_to'] as String?,
      resolvedAt: dateTimeFromJson(json['resolved_at']),
      firstResponseAt: dateTimeFromJson(json['first_response_at']),
      closedAt: dateTimeFromJson(json['closed_at']),
      resolutionNote: json['resolution_note'] as String?,
      metadata: mapFromJson(json['metadata']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_number': ticketNumber,
    'user_id': userId,
    'order_id': orderId,
    'category': enumToSnake(category),
    'priority': enumToSnake(priority),
    'status': enumToSnake(status),
    'subject': subject,
    'description': description,
    'attachments': attachments,
    'assigned_to': assignedTo,
    'resolved_at': dateTimeToJson(resolvedAt),
    'first_response_at': dateTimeToJson(firstResponseAt),
    'closed_at': dateTimeToJson(closedAt),
    'resolution_note': resolutionNote,
    'metadata': metadata,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
