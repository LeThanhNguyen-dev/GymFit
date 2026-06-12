import '../../../../core/models/model_converters.dart';

class AddressModel {
  const AddressModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.ward,
    this.district,
    required this.city,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String addressLine1;
  final String? addressLine2;
  final String? ward;
  final String? district;
  final String city;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    parts.add(city);
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city']?.toString() ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'is_default': isDefault,
      'created_at': dateTimeToJson(createdAt),
      'updated_at': dateTimeToJson(updatedAt),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'is_default': isDefault,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'is_default': isDefault,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
