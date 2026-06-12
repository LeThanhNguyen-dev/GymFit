import '../../../../core/models/model_converters.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
    this.sellerStatus = 'none',
    this.isAdmin = false,
    this.metadata = const {},
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String sellerStatus;
  final bool isAdmin;
  final Map<String, dynamic> metadata;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role']?.toString() ?? 'customer',
      sellerStatus: json['seller_status']?.toString() ?? 'none',
      isAdmin: json['is_admin'] as bool? ?? false,
      metadata: mapFromJson(json['metadata']),
      lastLoginAt: dateTimeFromJson(json['last_login_at']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'seller_status': sellerStatus,
      'is_admin': isAdmin,
      'metadata': metadata,
      'last_login_at': dateTimeToJson(lastLoginAt),
      'created_at': dateTimeToJson(createdAt),
      'updated_at': dateTimeToJson(updatedAt),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    return data;
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? sellerStatus,
    bool? isAdmin,
    Map<String, dynamic>? metadata,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      metadata: metadata ?? this.metadata,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
