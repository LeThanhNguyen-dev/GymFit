import 'package:flutter/material.dart';
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

// ─────────────────────────────────────────────
// Category palette & icon mapping
// ─────────────────────────────────────────────

const List<Color> categoryColors = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFFD81B60), // pink
  Color(0xFF6D4C41), // brown
  Color(0xFF546E7A), // bluegrey
];

IconData _iconForCategory(String name) {
  const icons = <String, IconData>{
    'Thực Phẩm Bổ Sung': Icons.medication_liquid,
    'Dụng Cụ Tập Luyện': Icons.fitness_center,
    'Phụ Kiện Gym': Icons.backpack,
    'Thời Trang Gym Nam': Icons.male,
    'Thời Trang Gym Nữ': Icons.female,
    'Thiết Bị Cardio': Icons.directions_run,
    'Yoga & Fitness': Icons.self_improvement,
    'Phục Hồi Cơ Thể': Icons.spa,
    'Combo & Khuyến Mãi': Icons.local_offer,
    'Protein': Icons.science,
    'Tăng Cơ': Icons.trending_up,
    'Giảm Mỡ': Icons.local_fire_department,
    'Năng Lượng': Icons.bolt,
    'Phục Hồi Dinh Dưỡng': Icons.healing,
    'Vitamin & Khoáng Chất': Icons.table_restaurant,
    'Tạ': Icons.monitor_weight,
    'Resistance': Icons.straighten,
    'Bodyweight': Icons.accessibility_new,
    'Functional Training': Icons.swap_vert,
    'Home Gym': Icons.home,
    'Bảo Hộ': Icons.shield,
    'Hỗ Trợ Nâng Tạ': Icons.handyman,
    'Tiện Ích': Icons.build,
    'Công Nghệ': Icons.devices,
    'Massage': Icons.spa,
    'Recovery Gear': Icons.loop,
    'Therapy': Icons.medical_services,
    'Whey Protein': Icons.water_drop,
    'Isolate Protein': Icons.water,
    'Casein Protein': Icons.card_giftcard,
    'Vegan Protein': Icons.eco,
    'Creatine': Icons.biotech,
    'Mass Gainer': Icons.cake,
    'Pre Workout': Icons.flash_on,
    'BCAA': Icons.blur_on,
    'Combo Tăng Cơ': Icons.card_giftcard,
    'Combo Giảm Mỡ': Icons.card_giftcard,
    'Combo Người Mới': Icons.card_giftcard,
  };
  return icons[name] ?? Icons.category;
}

// Menu item model for easier handling
class MenuItemModel {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final IconData icon;
  final int colorIndex;
  final int productCount;
  final List<MenuItemModel> children;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    IconData? icon,
    int? colorIndex,
    this.productCount = 0,
    this.children = const [],
  }) : icon = icon ?? _iconForCategory(name),
       colorIndex = colorIndex ?? (name.hashCode % categoryColors.length);

  factory MenuItemModel.fromCategory(CategoryModel category, {int productCount = 0}) {
    return MenuItemModel(
      id: category.id,
      name: category.name,
      slug: category.slug,
      imageUrl: category.imageUrl,
      productCount: productCount,
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
    int colorIdx = 0;
    
    for (final rootCategory in rootCategories) {
      // Get level 2
      final level2Rows = await client
          .from('categories')
          .select()
          .eq('parent_id', rootCategory.id)
          .order('sort_order');
      
      final level2Items = <MenuItemModel>[];
      int l2ColorIdx = 0;
      
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
            colorIndex: l2ColorIdx++,
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
          colorIndex: colorIdx++,
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
      id: '1', name: 'Thực Phẩm Bổ Sung', slug: 'thuc-pham-bo-sung',
      colorIndex: 0,
      children: [
        MenuItemModel(
          id: '1-1', name: 'Protein', slug: 'protein', colorIndex: 0,
          children: [
            MenuItemModel(id: '1-1-1', name: 'Whey Protein', slug: 'whey-protein'),
            MenuItemModel(id: '1-1-2', name: 'Isolate Protein', slug: 'isolate-protein'),
            MenuItemModel(id: '1-1-3', name: 'Casein Protein', slug: 'casein-protein'),
          ],
        ),
        MenuItemModel(
          id: '1-2', name: 'Tăng Cơ', slug: 'tang-co', colorIndex: 1,
          children: [
            MenuItemModel(id: '1-2-1', name: 'Creatine', slug: 'creatine'),
            MenuItemModel(id: '1-2-2', name: 'Mass Gainer', slug: 'mass-gainer'),
          ],
        ),
        MenuItemModel(
          id: '1-3', name: 'Giảm Mỡ', slug: 'giam-mo', colorIndex: 2,
          children: [
            MenuItemModel(id: '1-3-1', name: 'Fat Burner', slug: 'fat-burner'),
            MenuItemModel(id: '1-3-2', name: 'L-Carnitine', slug: 'l-carnitine'),
          ],
        ),
        MenuItemModel(
          id: '1-4', name: 'Năng Lượng', slug: 'nang-luong', colorIndex: 3,
          children: [
            MenuItemModel(id: '1-4-1', name: 'Pre Workout', slug: 'pre-workout'),
            MenuItemModel(id: '1-4-2', name: 'Energy Gel', slug: 'energy-gel'),
          ],
        ),
        MenuItemModel(
          id: '1-5', name: 'Phục Hồi Dinh Dưỡng', slug: 'phuc-hoi', colorIndex: 4,
          children: [
            MenuItemModel(id: '1-5-1', name: 'BCAA', slug: 'bcaa'),
            MenuItemModel(id: '1-5-2', name: 'Glutamine', slug: 'glutamine'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '2', name: 'Dụng Cụ Tập Luyện', slug: 'dung-cu-tap-luyen',
      colorIndex: 1,
      children: [
        MenuItemModel(id: '2-1', name: 'Tạ', slug: 'ta', colorIndex: 0,
          children: [
            MenuItemModel(id: '2-1-1', name: 'Tạ Tay', slug: 'ta-tay'),
            MenuItemModel(id: '2-1-2', name: 'Tạ Đòn', slug: 'ta-don'),
            MenuItemModel(id: '2-1-3', name: 'Bánh Tạ', slug: 'banh-ta'),
          ],
        ),
        MenuItemModel(id: '2-2', name: 'Resistance', slug: 'resistance', colorIndex: 1,
          children: [
            MenuItemModel(id: '2-2-1', name: 'Resistance Band', slug: 'resistance-band'),
            MenuItemModel(id: '2-2-2', name: 'Pull Up Assist', slug: 'pull-up-assist'),
          ],
        ),
        MenuItemModel(id: '2-3', name: 'Bodyweight', slug: 'bodyweight', colorIndex: 2,
          children: [
            MenuItemModel(id: '2-3-1', name: 'Xà Đơn', slug: 'xa-don'),
            MenuItemModel(id: '2-3-2', name: 'Xà Kép', slug: 'xa-kep'),
          ],
        ),
        MenuItemModel(id: '2-4', name: 'Home Gym', slug: 'home-gym', colorIndex: 3,
          children: [
            MenuItemModel(id: '2-4-1', name: 'Power Rack', slug: 'power-rack'),
            MenuItemModel(id: '2-4-2', name: 'Squat Rack', slug: 'squat-rack'),
            MenuItemModel(id: '2-4-3', name: 'Bench Press', slug: 'bench-press'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '3', name: 'Phụ Kiện Gym', slug: 'phu-kien-gym', colorIndex: 2,
      children: [
        MenuItemModel(id: '3-1', name: 'Bảo Hộ', slug: 'bao-ho', colorIndex: 0,
          children: [
            MenuItemModel(id: '3-1-1', name: 'Đai Lưng', slug: 'dai-lung'),
            MenuItemModel(id: '3-1-2', name: 'Quấn Cổ Tay', slug: 'quan-co-tay'),
          ],
        ),
        MenuItemModel(id: '3-2', name: 'Tiện Ích', slug: 'tien-ich', colorIndex: 1,
          children: [
            MenuItemModel(id: '3-2-1', name: 'Bình Nước', slug: 'binh-nuoc'),
            MenuItemModel(id: '3-2-2', name: 'Khăn Tập', slug: 'khan-tap'),
          ],
        ),
        MenuItemModel(id: '3-3', name: 'Công Nghệ', slug: 'cong-nghe', colorIndex: 2,
          children: [
            MenuItemModel(id: '3-3-1', name: 'Smart Watch', slug: 'smart-watch'),
            MenuItemModel(id: '3-3-2', name: 'Earbuds', slug: 'earbuds'),
          ],
        ),
      ],
    ),
    MenuItemModel(
      id: '4', name: 'Thời Trang Gym Nam', slug: 'thoi-trang-gym-nam', colorIndex: 3,
      children: [
        MenuItemModel(id: '4-1', name: 'Áo Nam', slug: 'ao-nam', colorIndex: 0,
          children: [
            MenuItemModel(id: '4-1-1', name: 'T-Shirt', slug: 't-shirt'),
            MenuItemModel(id: '4-1-2', name: 'Tank Top', slug: 'tank-top'),
            MenuItemModel(id: '4-1-3', name: 'Compression Shirt', slug: 'compression-shirt'),
          ],
        ),
        MenuItemModel(id: '4-2', name: 'Quần Nam', slug: 'quan-nam', colorIndex: 1,
          children: [
            MenuItemModel(id: '4-2-1', name: 'Short', slug: 'short'),
            MenuItemModel(id: '4-2-2', name: 'Jogger', slug: 'jogger'),
            MenuItemModel(id: '4-2-3', name: 'Compression Pants', slug: 'compression-pants'),
          ],
        ),
        MenuItemModel(id: '4-3', name: 'Giày Nam', slug: 'giay-nam', colorIndex: 2),
      ],
    ),
    MenuItemModel(
      id: '5', name: 'Thời Trang Gym Nữ', slug: 'thoi-trang-gym-nu', colorIndex: 4,
      children: [
        MenuItemModel(id: '5-1', name: 'Áo Nữ', slug: 'ao-nu', colorIndex: 0),
        MenuItemModel(id: '5-2', name: 'Quần Nữ', slug: 'quan-nu', colorIndex: 1),
        MenuItemModel(id: '5-3', name: 'Giày Nữ', slug: 'giay-nu', colorIndex: 2),
      ],
    ),
    MenuItemModel(
      id: '6', name: 'Thiết Bị Cardio', slug: 'thiet-bi-cardio', colorIndex: 5,
      children: [
        MenuItemModel(id: '6-1', name: 'Máy Chạy Bộ', slug: 'may-chay-bo', colorIndex: 0),
        MenuItemModel(id: '6-2', name: 'Xe Đạp Tập', slug: 'xe-dap-tap', colorIndex: 1),
      ],
    ),
    MenuItemModel(
      id: '7', name: 'Yoga & Fitness', slug: 'yoga-fitness', colorIndex: 6,
      children: [
        MenuItemModel(id: '7-1', name: 'Yoga', slug: 'yoga', colorIndex: 0),
        MenuItemModel(id: '7-2', name: 'Pilates', slug: 'pilates', colorIndex: 1),
        MenuItemModel(id: '7-3', name: 'Mobility', slug: 'mobility', colorIndex: 2),
      ],
    ),
    MenuItemModel(
      id: '8', name: 'Phục Hồi Cơ Thể', slug: 'phuc-hoi-co-the', colorIndex: 7,
      children: [
        MenuItemModel(id: '8-1', name: 'Massage', slug: 'massage', colorIndex: 0),
        MenuItemModel(id: '8-2', name: 'Recovery Gear', slug: 'recovery-gear', colorIndex: 1),
      ],
    ),
    MenuItemModel(
      id: '9', name: 'Combo & Khuyến Mãi', slug: 'combo-khuyen-mai', colorIndex: 8,
      children: [
        MenuItemModel(id: '9-1', name: 'Combo Tăng Cơ', slug: 'combo-tang-co', colorIndex: 0),
        MenuItemModel(id: '9-2', name: 'Combo Giảm Mỡ', slug: 'combo-giam-mo', colorIndex: 1),
        MenuItemModel(id: '9-3', name: 'Combo Người Mới', slug: 'combo-nguoi-moi', colorIndex: 2),
      ],
    ),
  ];
}
