import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../products/data/models/product_model.dart';
import '../../../../products/providers/product_providers.dart';
import '../../../../../shared/enums/database_enums.dart';

class StoreProductListScreen extends ConsumerStatefulWidget {
  const StoreProductListScreen({super.key});
  @override
  ConsumerState<StoreProductListScreen> createState() => _StoreProductListScreenState();
}

class _StoreProductListScreenState extends ConsumerState<StoreProductListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(storeProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.sm, AppSpacing.pageHorizontal, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Tất cả|Đang bán|Hết hàng|Ẩn|Nháp'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Apply search filter
                var filtered = products;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((p) => p.name.toLowerCase().contains(_searchQuery) || (p.sku ?? '').toLowerCase().contains(_searchQuery))
                      .toList();
                }

                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildProductList(filtered), // Tất cả
                    _buildProductList(filtered.where((p) => p.status == ProductStatus.active).toList()), // Đang bán
                    _buildProductList(filtered.where((p) {
                      if (p.status != ProductStatus.active) return false;
                      if (p.variants.isEmpty) return false;
                      return p.variants.every((v) => v.quantity <= 0);
                    }).toList()), // Hết hàng
                    _buildProductList(filtered.where((p) => p.status == ProductStatus.inactive).toList()), // Ẩn
                    _buildProductList(filtered.where((p) => p.status == ProductStatus.draft).toList()), // Nháp
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
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

  Widget _buildProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nào.'));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(storeProductsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _ProductCard(
          product: products[i],
          onTap: () => context.push(RouteNames.storeEditProductPath.replaceAll(':id', products[i].id)),
          onStatusChanged: (newStatus) async {
            try {
              final repo = ref.read(productRepositoryProvider);
              await repo.updateProduct(products[i].id, {'status': newStatus});
              ref.invalidate(storeProductsProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            }
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Xóa sản phẩm?'),
                content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                final repo = ref.read(productRepositoryProvider);
                await repo.deleteProduct(products[i].id);
                ref.invalidate(storeProductsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            }
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  Color _statusColor(ProductStatus s) => switch (s) {
        ProductStatus.active => AppColors.success,
        ProductStatus.inactive => Colors.grey,
        ProductStatus.draft => AppColors.info,
        _ => AppColors.warning,
      };

  String _statusText(ProductStatus s) => switch (s) {
        ProductStatus.active => 'Đang bán',
        ProductStatus.inactive => 'Ẩn',
        ProductStatus.draft => 'Nháp',
        _ => 'Chờ duyệt',
      };

  @override
  Widget build(BuildContext context) {
    final hasStock = product.variants.isNotEmpty ? product.variants.fold<int>(0, (sum, v) => sum + v.quantity) : 0;
    final displayStatusText = hasStock == 0 && product.status == ProductStatus.active ? 'Hết hàng' : _statusText(product.status);
    final statusColor = hasStock == 0 && product.status == ProductStatus.active ? AppColors.error : _statusColor(product.status);

    return Card(
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            image: product.primaryImageUrl != null
                ? DecorationImage(image: NetworkImage(product.primaryImageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: product.primaryImageUrl == null
              ? Icon(Icons.image, color: AppColors.onSurfaceVariant)
              : null,
        ),
        title: Text(product.name, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${product.basePrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫ • Tồn: $hasStock',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayStatusText,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  onTap();
                } else if (val == 'hide') {
                  onStatusChanged('inactive');
                } else if (val == 'show') {
                  onStatusChanged('active');
                } else if (val == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                if (product.status == ProductStatus.active)
                  const PopupMenuItem(value: 'hide', child: Text('Ẩn')),
                if (product.status == ProductStatus.inactive || product.status == ProductStatus.draft)
                  const PopupMenuItem(value: 'show', child: Text('Hiện thị (Bán)')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
