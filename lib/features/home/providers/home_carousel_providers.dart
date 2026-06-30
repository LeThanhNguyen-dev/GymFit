import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/carousel_item.dart';

final carouselItemsProvider = FutureProvider<List<CarouselItem>>((ref) async {
  final client = Supabase.instance.client;
  final items = <CarouselItem>[];

  try {
    final banners = await client
        .from('banners')
        .select('id, title, subtitle, image_url, button_text, redirect_url')
        .eq('is_active', true)
        .order('sort_order');

    for (final row in banners) {
      items.add(CarouselItem(
        id: row['id'].toString(),
        title: row['title'].toString(),
        subtitle: row['subtitle'] as String?,
        imageUrl: row['image_url'].toString(),
        buttonText: row['button_text'] as String?,
        onTapAction: row['redirect_url'] as String?,
      ));
    }
  } catch (_) {}

  try {
    final services = await client
        .from(AppConstants.servicesTable)
        .select('id, name, description, image_url, slug')
        .eq('is_active', true)
        .order('sort_order');

    for (final row in services) {
      final imageUrl = row['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) continue;
      items.add(CarouselItem(
        id: 'svc_${row['id']}',
        title: row['name'].toString(),
        subtitle: row['description'] as String?,
        imageUrl: imageUrl,
        buttonText: 'Đăng ký ngay',
        onTapAction: '/services/${row['slug']}',
      ));
    }
  } catch (_) {}

  return items;
});
