import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.isActive = true,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isAdmin = false,
    this.loyaltyPoints = 0,
    this.referralCode,
    this.referredBy,
    this.lastLoginAt,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final GenderType? gender;
  final DateTime? dateOfBirth;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isAdmin;
  final int loyaltyPoints;
  final String? referralCode;
  final String? referredBy;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      email: json['email'].toString(),
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] == null
          ? null
          : enumFromSnake(GenderType.values, json['gender'], GenderType.other),
      dateOfBirth: dateTimeFromJson(json['date_of_birth']),
      isActive: json['is_active'] as bool? ?? true,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      loyaltyPoints: intFromJson(json['loyalty_points']) ?? 0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      lastLoginAt: dateTimeFromJson(json['last_login_at']),
      metadata: mapFromJson(json['metadata']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'gender': gender == null ? null : enumToSnake(gender!),
      'date_of_birth': dateToJson(dateOfBirth),
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_admin': isAdmin,
      'loyalty_points': loyaltyPoints,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'last_login_at': dateTimeToJson(lastLoginAt),
      'metadata': metadata,
      'created_at': dateTimeToJson(createdAt),
      'updated_at': dateTimeToJson(updatedAt),
    };
  }
}
