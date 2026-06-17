import 'package:flutter/material.dart';

class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.gradientStart,
    this.gradientEnd,
    this.iconName,
    this.targetRoute,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? gradientStart;
  final String? gradientEnd;
  final String? iconName;
  final String? targetRoute;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      gradientStart: json['gradient_start'] as String?,
      gradientEnd: json['gradient_end'] as String?,
      iconName: json['icon_name'] as String?,
      targetRoute: json['target_route'] as String?,
    );
  }

  Color? get startColor {
    if (gradientStart == null) return null;
    try {
      return Color(int.parse(gradientStart!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  Color? get endColor {
    if (gradientEnd == null) return null;
    try {
      return Color(int.parse(gradientEnd!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  IconData get icon {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;
      case 'local_pharmacy_outlined':
        return Icons.local_pharmacy_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'star':
        return Icons.star;
      default:
        return Icons.image_outlined;
    }
  }
}
