import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../providers/brand_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/comparison_providers.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.categoryId,
    this.brandId,
    this.title,
  });

  final String? categoryId;
  final String? brandId;
  final String? title;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  bool _filtersApplied = false;

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_filtersApplied && (widget.categoryId != null || widget.brandId != null)) {
      _filtersApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          final notifier = ref.read(productListProvider.notifier);
          if (widget.categoryId != null) {
            notifier.updateCategory(widget.categoryId);
          }
          if (widget.brandId != null) {
            notifier.updateBrand(widget.brandId);
          }
        });
      });
    }
    final state = ref.watch(productListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);

    final screenTitle =
        widget.title ??
        selectedCategory?.name ??
        selectedBrand?.name ??
        'Tất cả sản phẩm';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: ref.watch(comparisonProvider).isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/compare'),
              icon: const Icon(Icons.compare_arrows),
              label: Text('So sánh (${ref.watch(comparisonProvider).length})'),
            )
          : null,
      body: Column(
        children: [
          // Active Filters Row
          if (selectedCategory != null ||
              selectedBrand != null ||
              state.minPrice != null)
            _ActiveFiltersRow(
              state: state,
              onClearCategory: () {
                ref.read(selectedCategoryProvider.notifier).clear();
                ref.read(productListProvider.notifier).updateCategory(null);
              },
              onClearBrand: () {
                ref.read(selectedBrandProvider.notifier).clear();
                ref.read(productListProvider.notifier).updateBrand(null);
              },
              onClearPrice: () {
                ref
                    .read(productListProvider.notifier)
                    .updatePriceRange(null, null);
              },
            ),

          // Sort Row
          _SortRow(state: state),

          // Product Grid
          Expanded(
            child: state.isLoading
                ? _buildShimmerGrid()
                : state.errorMessage != null
                ? _buildError(state.errorMessage!)
                : state.products.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.read(productListProvider.notifier).loadProducts(),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount:
                          state.products.length +
                          (state.isLoadMoreRunning ? 2 : 0),
                      itemBuilder: (context, i) {
                        if (i >= state.products.length) {
                          return const ProductCardShimmer();
                        }
                        final product = state.products[i];
                        return ProductCard(
                          product: product,
                          onTap: () => context.push('/products/${product.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => const ProductCardShimmer(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(productListProvider.notifier).loadProducts(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(ref: ref),
    );
  }
}

// ── Active Filters Row ────────────────────────────────────────────────────────

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({
    required this.state,
    required this.onClearCategory,
    required this.onClearBrand,
    required this.onClearPrice,
  });

  final ProductListState state;
  final VoidCallback onClearCategory;
  final VoidCallback onClearBrand;
  final VoidCallback onClearPrice;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (state.categoryId != null)
            _FilterChip(label: 'Danh mục', onRemove: onClearCategory),
          if (state.brandId != null)
            _FilterChip(label: 'Thương hiệu', onRemove: onClearBrand),
          if (state.minPrice != null || state.maxPrice != null)
            _FilterChip(
              label:
                  '${formatCurrency(state.minPrice ?? 0)} - ${formatCurrency(state.maxPrice ?? 999999999)}',
              onRemove: onClearPrice,
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort Row ──────────────────────────────────────────────────────────────────

class _SortRow extends ConsumerWidget {
  const _SortRow({required this.state});
  final ProductListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <String, (String, bool)>{
      'Mới nhất': ('created_at', false),
      'Giá thấp': ('base_price', true),
      'Giá cao': ('base_price', false),
      'Đánh giá': ('avg_rating', false),
      'Bán chạy': ('total_sold', false),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected =
              state.sortBy == entry.value.$1 &&
              state.ascending == entry.value.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(productListProvider.notifier)
                    .updateSort(entry.value.$1, entry.value.$2);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  double _minPrice = 0;
  double _maxPrice = 5000000;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final brandsAsync = ref.watch(brandListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ lọc',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(selectedCategoryProvider.notifier).clear();
                    ref.read(selectedBrandProvider.notifier).clear();
                    ref.read(productListProvider.notifier).clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh mục',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (cats) => Wrap(
                      spacing: 8,
                      children: cats
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c.name),
                              selected: selectedCategory?.id == c.id,
                              onSelected: (_) {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .select(c);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thương hiệu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  brandsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (brands) => Wrap(
                      spacing: 8,
                      children: brands
                          .map(
                            (b) => ChoiceChip(
                              label: Text(b.name),
                              selected: selectedBrand?.id == b.id,
                              onSelected: (_) {
                                ref
                                    .read(selectedBrandProvider.notifier)
                                    .select(b);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Khoảng giá',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatCurrency(_minPrice),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatCurrency(_maxPrice),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  RangeSlider(
                    min: 0,
                    max: 5000000,
                    divisions: 50,
                    values: RangeValues(_minPrice, _maxPrice),
                    onChanged: (values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: FilledButton(
              onPressed: () {
                ref
                    .read(productListProvider.notifier)
                    .updateCategory(selectedCategory?.id);
                ref
                    .read(productListProvider.notifier)
                    .updateBrand(selectedBrand?.id);
                ref
                    .read(productListProvider.notifier)
                    .updatePriceRange(
                      _minPrice > 0 ? _minPrice : null,
                      _maxPrice < 5000000 ? _maxPrice : null,
                    );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}
