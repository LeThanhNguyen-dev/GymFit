import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class AddressModel {
  const AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.city,
    this.type = AddressType.home,
    this.addressLine2,
    this.ward,
    this.district,
    this.province,
    this.country = 'VN',
    this.postalCode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final AddressType type;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String? ward;
  final String? district;
  final String city;
  final String? province;
  final String country;
  final String? postalCode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    type: enumFromSnake(AddressType.values, json['type'], AddressType.home),
    fullName: json['full_name'].toString(),
    phone: json['phone'].toString(),
    addressLine1: json['address_line1'].toString(),
    addressLine2: json['address_line2'] as String?,
    ward: json['ward'] as String?,
    district: json['district'] as String?,
    city: json['city'].toString(),
    province: json['province'] as String?,
    country: json['country'] as String? ?? 'VN',
    postalCode: json['postal_code'] as String?,
    isDefault: json['is_default'] as bool? ?? false,
    latitude: doubleFromJson(json['latitude']),
    longitude: doubleFromJson(json['longitude']),
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': enumToSnake(type),
    'full_name': fullName,
    'phone': phone,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'ward': ward,
    'district': district,
    'city': city,
    'province': province,
    'country': country,
    'postal_code': postalCode,
    'is_default': isDefault,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };
}
