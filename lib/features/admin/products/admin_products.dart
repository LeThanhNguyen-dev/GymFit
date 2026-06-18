import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  String? _categoryFilter;
  String? _brandFilter;
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage products')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminProducts(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                status: _statusFilter,
                categoryId: _categoryFilter,
                brandId: _brandFilter,
                sortBy: _sortBy,
                ascending: _ascending,
                page: _page,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data!;
                final products = result.items;
                if (products.isEmpty) {
                  return const Center(child: Text('No products.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isInactive = product.status.name == 'inactive';
                      final variantCount = product.variants.length;
                      final totalStock = product.variants.fold<int>(
                        0,
                        (sum, v) => sum + v.quantity,
                      );
                      return ListTile(
                        title: Text(
                          product.name,
                          style: isInactive
                              ? const TextStyle(color: Colors.grey)
                              : null,
                        ),
                        subtitle: Text(
                          '${product.status.name} - ${product.basePrice.round()}d'
                          '  |  $variantCount variants'
                          '  |  $totalStock in stock'
                          '${product.seller != null ? '  |  ${product.seller!.fullName ?? product.seller!.email ?? ''}' : ''}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'View details',
                              onPressed: () =>
                                  _showDetailDialog(product),
                            ),
                            if (isInactive)
                              IconButton(
                                icon: const Icon(Icons.restore,
                                    color: Colors.green),
                                tooltip: 'Restore',
                                onPressed: () async {
                                  await repository.restoreProduct(product.id);
                                  if (mounted) setState(() {});
                                },
                              )
                            else ...[
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showProductDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Deactivate product?'),
                                      content: Text(
                                        'Set "${product.name}" as inactive?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Deactivate'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await repository
                                        .softDeleteProduct(product.id);
                                    if (mounted) setState(() {});
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search products',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('All', null),
            const SizedBox(width: 8),
            _buildStatusChip('Active', 'active'),
            const SizedBox(width: 8),
            _buildStatusChip('Draft', 'draft'),
            const SizedBox(width: 8),
            _buildStatusChip('Inactive', 'inactive'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _statusFilter = selected ? null : value;
          _page = 1;
        });
      },
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Mới nhất'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('name', 'Name A-Z'),
      SortOption('name_desc', 'Name Z-A'),
      SortOption('base_price', 'Price low-high'),
      SortOption('base_price_desc', 'Price high-low'),
      SortOption('total_sold_desc', 'Bán chạy'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SortDropdown(
        value: currentKey,
        options: sortOptions,
        onChanged: (key) {
          setState(() {
            if (key.endsWith('_desc')) {
              _sortBy = key.replaceAll('_desc', '');
              _ascending = false;
            } else {
              _sortBy = key;
              _ascending = true;
            }
            _page = 1;
          });
        },
      ),
    );
  }

  Widget _buildPagination() {
    return FutureBuilder(
      future: ref.read(productRepositoryProvider).getAdminProducts(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _statusFilter,
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
        pageSize: 20,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        final totalPages = (result.totalCount / 20).ceil();
        return PaginationBar(
          page: _page,
          totalPages: totalPages,
          totalItems: result.totalCount,
          onPageChanged: (p) => setState(() => _page = p),
        );
      },
    );
  }

  void _showDetailDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Status', product.status.name),
              _detailRow('Price', '${product.basePrice.round()}d'),
              _detailRow('Slug', product.slug),
              _detailRow(
                'Category',
                product.category?.name ?? product.categoryId,
              ),
              _detailRow(
                'Brand',
                product.brand?.name ?? product.brandId ?? '-',
              ),
              _detailRow(
                'Seller',
                product.seller != null
                    ? '${product.seller!.fullName ?? ''} (${product.seller!.email ?? product.userId ?? ''})'
                    : product.userId ?? '-',
              ),
              _detailRow('Total sold', '${product.totalSold}'),
              _detailRow('Featured', product.isFeatured ? 'Yes' : 'No'),
              if (product.variants.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Variants (${product.variants.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...product.variants.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${v.name ?? v.optionDisplay}: ${v.quantity} in stock'
                      '${v.sku.isNotEmpty ? ' (${v.sku})' : ''}'
                      ' - ${v.price.round()}d',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showProductDialog(ProductModel? product) async {
    final name = TextEditingController(text: product?.name);
    final slug = TextEditingController(text: product?.slug);
    final categoryId = TextEditingController(text: product?.categoryId);
    final brandId = TextEditingController(text: product?.brandId);
    final price = TextEditingController(
      text: product?.basePrice.toString() ?? '0',
    );
    var featured = product?.isFeatured ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(product == null ? 'Add product' : 'Edit product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: slug,
                  decoration: const InputDecoration(labelText: 'Slug'),
                ),
                TextField(
                  controller: categoryId,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                ),
                TextField(
                  controller: brandId,
                  decoration: const InputDecoration(
                    labelText: 'Brand ID optional',
                  ),
                ),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Base price'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: featured,
                  onChanged: (value) => setLocalState(() => featured = value),
                  title: const Text('Featured'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(productRepositoryProvider).saveProduct({
                  'name': name.text.trim(),
                  'slug': slug.text.trim(),
                  'category_id': categoryId.text.trim(),
                  'brand_id': brandId.text.trim().isEmpty
                      ? null
                      : brandId.text.trim(),
                  'base_price': double.tryParse(price.text.trim()) ?? 0,
                  'status': 'active',
                  'is_featured': featured,
                }, id: product?.id);
                if (mounted) setState(() {});
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
