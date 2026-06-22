import 'package:flutter/material.dart';

import '../../../../core/providers/menu_providers.dart';
import 'category_landing_screen.dart';

/// Legacy wrapper — delegates to [CategoryLandingScreen].
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.item,
  });

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return CategoryLandingScreen(item: item);
  }
}
