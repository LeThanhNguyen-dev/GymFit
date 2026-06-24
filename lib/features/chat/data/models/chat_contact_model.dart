class ChatContactModel {
  const ChatContactModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'storeowner':
        return 'Chủ shop';
      default:
        return 'Khách hàng';
    }
  }

  String get initials {
    final source = fullName.isNotEmpty ? fullName : email;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      id: json['id'].toString(),
      fullName: json['full_name']?.toString() ?? json['email']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role']?.toString() ?? 'customer',
    );
  }
}
