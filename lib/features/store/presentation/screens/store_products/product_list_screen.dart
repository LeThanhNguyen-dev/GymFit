import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class StoreProductListScreen extends ConsumerStatefulWidget {
  const StoreProductListScreen({super.key});
  @override
  ConsumerState<StoreProductListScreen> createState() => _StoreProductListScreenState();
}

class _StoreProductListScreenState extends ConsumerState<StoreProductListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 5, vsync: this); }

  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.sm, AppSpacing.pageHorizontal, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Tất cả|Đang bán|Hết hàng|Ẩn|Chờ duyệt'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: List.generate(5, (_) => _buildProductList()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.storeAddProductPath),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  Widget _buildProductList() {
    final products = [
      _mockProduct('Gym Bag Pro', '1.200.000₫', 45, 'Đang bán'),
      _mockProduct('Towel XL', '250.000₫', 0, 'Hết hàng'),
      _mockProduct('Water Bottle 500ml', '180.000₫', 120, 'Đang bán'),
      _mockProduct('Wrist Wraps', '350.000₫', 0, 'Ẩn'),
      _mockProduct('Jump Rope Speed', '220.000₫', 60, 'Đang bán'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _ProductCard(product: products[i], onTap: () {}),
    );
  }

  Map<String, dynamic> _mockProduct(String name, String price, int stock, String status) =>
      {'name': name, 'price': price, 'stock': stock, 'status': status, 'image': Icons.image};
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  Color _statusColor(String s) => switch (s) {
    'Đang bán' => AppColors.success, 'Hết hàng' => AppColors.error, 'Ẩn' => Colors.grey, _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.image, color: AppColors.onSurfaceVariant),
        ),
        title: Text(product['name'], style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${product['price']} • Tồn: ${product['stock']}', style: AppTextStyles.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _statusColor(product['status']).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(product['status'], style: TextStyle(fontSize: 11, color: _statusColor(product['status']))),
            ),
            PopupMenuButton(itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
              const PopupMenuItem(value: 'hide', child: Text('Ẩn')),
              const PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ]),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
