import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/products/data/models/product_model.dart';

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
  try {
    final client = ref.watch(supabaseClientProvider);
    
    // Get all root categories (parent_id IS NULL)
    final rootRows = await client
        .from('categories')
        .select()
        .isFilter('parent_id', null)
        .order('sort_order');
    
    if (rootRows.isEmpty) {
      debugPrint('No root categories found, using test data');
      return _getTestMenuData();
    }
    
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
  } catch (e) {
    debugPrint('Error fetching menu: $e');
    // Return test data on error
    return _getTestMenuData();
  }
});

// Test data for development/debugging
List<MenuItemModel> _getTestMenuData() {
  return [
    MenuItemModel(
      id: '1',
      name: 'Quần áo',
      slug: 'quan-ao',
      children: [
        MenuItemModel(
          id: '1-1',
          name: 'Nam',
          slug: 'quan-ao-nam',
          children: [
            MenuItemModel(id: '1-1-1', name: 'Áo thể thao', slug: 'ao-the-thao'),
            MenuItemModel(id: '1-1-2', name: 'Quần tập', slug: 'quan-tap'),
            MenuItemModel(id: '1-1-3', name: 'Áo khoác', slug: 'ao-khoac'),
          ],
        ),
        MenuItemModel(
          id: '1-2',
          name: 'Nữ',
          slug: 'quan-ao-nu',
          children: [
            MenuItemModel(id: '1-2-1', name: 'Áo thể thao', slug: 'ao-the-thao-nu'),
            MenuItemModel(id: '1-2-2', name: 'Legging', slug: 'legging'),
            MenuItemModel(id: '1-2-3', name: 'Áo khoác', slug: 'ao-khoac-nu'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '2',
      name: 'Giày dép',
      slug: 'giay-dep',
      children: [
        MenuItemModel(
          id: '2-1',
          name: 'Giày chạy',
          slug: 'giay-chay',
          children: [
            MenuItemModel(id: '2-1-1', name: 'Nike', slug: 'nike-chay'),
            MenuItemModel(id: '2-1-2', name: 'Adidas', slug: 'adidas-chay'),
            MenuItemModel(id: '2-1-3', name: 'Khác', slug: 'khac-chay'),
          ],
        ),
        MenuItemModel(
          id: '2-2',
          name: 'Giày tập',
          slug: 'giay-tap',
          children: [
            MenuItemModel(id: '2-2-1', name: 'Giày xù', slug: 'giay-xu'),
            MenuItemModel(id: '2-2-2', name: 'Giày cao cổ', slug: 'giay-cao-co'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '3',
      name: 'Phụ kiện',
      slug: 'phu-kien',
      children: [
        MenuItemModel(
          id: '3-1',
          name: 'Túi',
          slug: 'tui',
          children: [
            MenuItemModel(id: '3-1-1', name: 'Túi xách', slug: 'tui-xach'),
            MenuItemModel(id: '3-1-2', name: 'Túi đeo', slug: 'tui-deo'),
            MenuItemModel(id: '3-1-3', name: 'Balo', slug: 'balo'),
          ],
        ),
        MenuItemModel(
          id: '3-2',
          name: 'Khác',
          slug: 'phu-kien-khac',
          children: [
            MenuItemModel(id: '3-2-1', name: 'Tất', slug: 'tat'),
            MenuItemModel(id: '3-2-2', name: 'Khăn tập', slug: 'khan-tap'),
            MenuItemModel(id: '3-2-3', name: 'Mũ nón', slug: 'mu-non'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '4',
      name: 'Thực phẩm bổ sung',
      slug: 'thuc-pham-bo-sung',
      children: [
        MenuItemModel(
          id: '4-1',
          name: 'Protein',
          slug: 'protein',
          children: [
            MenuItemModel(id: '4-1-1', name: 'Whey Protein', slug: 'whey-protein'),
            MenuItemModel(id: '4-1-2', name: 'Casein', slug: 'casein'),
            MenuItemModel(id: '4-1-3', name: 'Plant-based', slug: 'plant-based'),
          ],
        ),
        MenuItemModel(
          id: '4-2',
          name: 'Pre-workout',
          slug: 'pre-workout',
          children: [
            MenuItemModel(id: '4-2-1', name: 'Caffeine', slug: 'caffeine'),
            MenuItemModel(id: '4-2-2', name: 'Energy', slug: 'energy'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '5',
      name: 'Thiết bị',
      slug: 'thiet-bi',
      children: [
        MenuItemModel(
          id: '5-1',
          name: 'Dụng cụ',
          slug: 'dung-cu',
          children: [
            MenuItemModel(id: '5-1-1', name: 'Tạ', slug: 'ta'),
            MenuItemModel(id: '5-1-2', name: 'Đầu tạ', slug: 'dau-ta'),
            MenuItemModel(id: '5-1-3', name: 'Dây kéo', slug: 'day-keo'),
          ],
        ),
        MenuItemModel(
          id: '5-2',
          name: 'Thiết bị điện tử',
          slug: 'thiet-bi-dien-tu',
          children: [
            MenuItemModel(id: '5-2-1', name: 'Vòng theo dõi', slug: 'vong-theo-doi'),
            MenuItemModel(id: '5-2-2', name: 'Cân sức khỏe', slug: 'can-suc-khoe'),
          ],
        ),
      ],
    ),
  ];
}
