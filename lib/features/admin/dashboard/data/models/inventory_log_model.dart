import '../../../../../core/models/model_converters.dart';

class InventoryLogModel {
  const InventoryLogModel({
    required this.id,
    required this.variantId,
    required this.changeType,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String variantId;
  final String changeType;
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String? note;
  final String? createdBy;
  final DateTime? createdAt;

  factory InventoryLogModel.fromJson(Map<String, dynamic> json) {
    return InventoryLogModel(
      id: json['id'].toString(),
      variantId: json['variant_id'].toString(),
      changeType: (json['change_type'] ?? json['action'] ?? 'adjustment')
          .toString(),
      quantityChange: intFromJson(json['quantity_change']) ?? 0,
      quantityBefore: intFromJson(json['quantity_before']) ?? 0,
      quantityAfter: intFromJson(json['quantity_after']) ?? 0,
      note: json['note'] as String?,
      createdBy: (json['created_by'] ?? json['performed_by']) as String?,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'variant_id': variantId,
    'change_type': changeType,
    'quantity_change': quantityChange,
    'quantity_before': quantityBefore,
    'quantity_after': quantityAfter,
    'note': note,
    'created_by': createdBy,
    'created_at': dateTimeToJson(createdAt),
  };
}
