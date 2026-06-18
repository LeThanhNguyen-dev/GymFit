import '../../../../../core/models/model_converters.dart';

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
    this.sellerStatus = 'none',
    this.isAdmin = false,
    this.isBanned = false,
    this.banReason,
    this.bannedAt,
    this.metadata = const {},
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.reviewCount = 0,
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
  final bool isBanned;
  final String? banReason;
  final DateTime? bannedAt;
  final Map<String, dynamic> metadata;
  final int totalOrders;
  final double totalSpent;
  final int reviewCount;
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

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'storeowner':
        return 'Store Owner';
      default:
        return 'Customer';
    }
  }

  String get sellerStatusLabel {
    switch (sellerStatus) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'None';
    }
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role']?.toString() ?? 'customer',
      sellerStatus: json['seller_status']?.toString() ?? 'none',
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      banReason: json['ban_reason'] as String?,
      bannedAt: dateTimeFromJson(json['banned_at']),
      metadata: mapFromJson(json['metadata']),
      totalOrders: intFromJson(json['total_orders']) ?? 0,
      totalSpent: doubleFromJson(json['total_spent']) ?? 0.0,
      reviewCount: intFromJson(json['review_count']) ?? 0,
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
      'is_banned': isBanned,
      'ban_reason': banReason,
      'banned_at': dateTimeToJson(bannedAt),
      'metadata': metadata,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'review_count': reviewCount,
      'last_login_at': dateTimeToJson(lastLoginAt),
      'created_at': dateTimeToJson(createdAt),
      'updated_at': dateTimeToJson(updatedAt),
    };
  }

  AdminUserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? sellerStatus,
    bool? isAdmin,
    bool? isBanned,
    String? banReason,
    DateTime? bannedAt,
    Map<String, dynamic>? metadata,
    int? totalOrders,
    double? totalSpent,
    int? reviewCount,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt,
      metadata: metadata ?? this.metadata,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      reviewCount: reviewCount ?? this.reviewCount,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
