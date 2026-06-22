class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.redirectUrl,
    this.buttonText,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.position = 'home',
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? redirectUrl;
  final String? buttonText;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String position;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json['id'].toString(),
    title: json['title'].toString(),
    subtitle: json['subtitle'] as String?,
    imageUrl: json['image_url'].toString(),
    redirectUrl: json['redirect_url'] as String?,
    buttonText: json['button_text'] as String?,
    startDate: json['start_date'] != null
        ? DateTime.tryParse(json['start_date'].toString())
        : null,
    endDate: json['end_date'] != null
        ? DateTime.tryParse(json['end_date'].toString())
        : null,
    isActive: json['is_active'] as bool? ?? true,
    position: json['position'] as String? ?? 'home',
    sortOrder: json['sort_order'] as int? ?? 0,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'image_url': imageUrl,
    'redirect_url': redirectUrl,
    'button_text': buttonText,
    'start_date': startDate?.toUtc().toIso8601String(),
    'end_date': endDate?.toUtc().toIso8601String(),
    'is_active': isActive,
    'position': position,
    'sort_order': sortOrder,
  };

  bool get isValid {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return isActive;
  }
}
