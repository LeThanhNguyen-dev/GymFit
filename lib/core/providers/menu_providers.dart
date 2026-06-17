import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/products/data/models/product_model.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../constants/app_constants.dart';

final supabaseClientProvider = Provider((ref) {
  return Supabase.instance.client;
});

// Fetch all root categories (level 1)
final rootCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('categories')
      .select()
      .isFilter('parent_id', null)
      .order('sort_order');
  
  return rows.map((row) => CategoryModel.fromJson(row)).toList();
});

// Fetch subcategories for a parent (level 2)
final subcategoriesProvider =
    FutureProvider.family<List<CategoryModel>, String>((ref, parentId) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('categories')
      .select()
      .eq('parent_id', parentId)
      .order('sort_order');
  
  return rows.map((row) => CategoryModel.fromJson(row)).toList();
});

// Fetch third level categories (level 3)
final thirdLevelCategoriesProvider =
    FutureProvider.family<List<CategoryModel>, String>((ref, parentId) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('categories')
      .select()
      .eq('parent_id', parentId)
      .order('sort_order');
  
  return rows.map((row) => CategoryModel.fromJson(row)).toList();
});

// Menu item model for easier handling
class MenuItemModel {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final List<MenuItemModel> children;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.children = const [],
  });

  factory MenuItemModel.fromCategory(CategoryModel category) {
    return MenuItemModel(
      id: category.id,
      name: category.name,
      slug: category.slug,
      imageUrl: category.imageUrl,
      children: [],
    );
  }
}

// Fetch complete menu hierarchy (all 3 levels)
final completeMenuProvider =
    FutureProvider<List<MenuItemModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  
  // Get all root categories
  final rootRows = await client
      .from('categories')
      .select()
      .isFilter('parent_id', null)
      .order('sort_order');
  
  final rootCategories =
      rootRows.map((row) => CategoryModel.fromJson(row)).toList();
  
  // Build complete hierarchy
  final menuItems = <MenuItemModel>[];
  
  for (final rootCategory in rootCategories) {
    // Get level 2
    final level2Rows = await client
        .from('categories')
        .select()
        .eq('parent_id', rootCategory.id)
        .order('sort_order');
    
    final level2Items = <MenuItemModel>[];
    
    for (final level2Row in level2Rows) {
      final level2Category = CategoryModel.fromJson(level2Row);
      
      // Get level 3
      final level3Rows = await client
          .from('categories')
          .select()
          .eq('parent_id', level2Category.id)
          .order('sort_order');
      
      final level3Items = level3Rows
          .map((row) => MenuItemModel.fromCategory(CategoryModel.fromJson(row)))
          .toList();
      
      level2Items.add(
        MenuItemModel(
          id: level2Category.id,
          name: level2Category.name,
          slug: level2Category.slug,
          imageUrl: level2Category.imageUrl,
          children: level3Items,
        ),
      );
    }
    
    menuItems.add(
      MenuItemModel(
        id: rootCategory.id,
        name: rootCategory.name,
        slug: rootCategory.slug,
        imageUrl: rootCategory.imageUrl,
        children: level2Items,
      ),
    );
  }
  
  return menuItems;
});
