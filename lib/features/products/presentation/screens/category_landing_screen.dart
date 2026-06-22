import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/menu_providers.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../home/data/models/banner_model.dart';
import '../../providers/product_providers.dart';
import '../../data/models/product_model.dart';
import '../widgets/product_card.dart';
// ─────────────────────────────────────────────
// Dark glassmorphism color palette
// ─────────────────────────────────────────────

const _bgColor = Color(0xFF0E0E10);
const _surfaceColor = Color(0xFF1A1A1E);
const _cardColor = Color(0x14FFFFFF);
const _borderColor = Color(0x1AFFFFFF);
const _textPrimary = Color(0xFFF5F5F7);
const _textSecondary = Color(0xFF98989D);

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────

class CategoryLandingScreen extends ConsumerStatefulWidget {
  const CategoryLandingScreen({super.key, required this.item});

  final MenuItemModel item;

  @override
  ConsumerState<CategoryLandingScreen> createState() =>
      _CategoryLandingScreenState();
}

class _CategoryLandingScreenState
    extends ConsumerState<CategoryLandingScreen> {
  final _scrollController = ScrollController();

  // Product listing state
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _sortBy = 'created_at';
  bool _ascending = false;
  String? _selectedSubId;
  String? _selectedGrandchildId;

  // Banner
  List<BannerModel> _banners = [];

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadBanners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  List<String> _getAllCategoryIds() {
    final ids = <String>[widget.item.id];
    for (final child in widget.item.children) {
      ids.add(child.id);
      for (final grandchild in child.children) {
        ids.add(grandchild.id);
      }
    }
    return ids;
  }

  String? _getActiveCategoryId() {
    return _selectedGrandchildId ?? _selectedSubId ?? widget.item.id;
  }

  Future<void> _loadBanners() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await client
          .from('banners')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('sort_order')
          .limit(5);
      if (mounted) {
        setState(() {
          _banners =
              rows.map((row) => BannerModel.fromJson(row)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final catId = _getActiveCategoryId();
      final items = await repo.getProducts(
        page: 1,
        pageSize: _pageSize,
        categoryId: catId,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (mounted) {
        setState(() {
          _allProducts = items;
          _isLoading = false;
          _hasMore = items.length >= _pageSize;
          _page = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final catId = _getActiveCategoryId();
      final items = await repo.getProducts(
        page: _page + 1,
        pageSize: _pageSize,
        categoryId: catId,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (mounted) {
        setState(() {
          _allProducts.addAll(items);
          _isLoadingMore = false;
          _hasMore = items.length >= _pageSize;
          _page++;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSubcategoryTap(String id) {
    setState(() {
      _selectedSubId = id;
      _selectedGrandchildId = null;
    });
    _loadProducts();
  }

  void _onGrandchildTap(String id) {
    setState(() => _selectedGrandchildId = id);
    _loadProducts();
  }

  void _onSortChange(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _ascending = ascending;
    });
    _loadProducts();
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── 1. Sticky Header ──
          _StickyHeader(
            title: widget.item.name,
            cartCount: cartCount,
            onBack: () => Navigator.pop(context),
            onSearch: () => context.push('/search'),
            onCart: () => context.push('/cart'),
          ),

          // ── 2. Hero Banner ──
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: _HeroBanner(banners: _banners),
            ),

          // ── 3. Subcategory Chips ──
          if (widget.item.children.isNotEmpty)
            SliverToBoxAdapter(
              child: _SubcategoryBar(
                subcategories: widget.item.children,
                selectedId: _selectedSubId,
                grandchildSelected: _selectedGrandchildId,
                onSubcategoryTap: _onSubcategoryTap,
                onGrandchildTap: _onGrandchildTap,
              ),
            ),

          // ── 4. Featured Products ──
          SliverToBoxAdapter(
            child: _SectionWrapper(
              title: 'Nổi bật',
              child: _FeaturedRow(categoryIds: _getAllCategoryIds()),
            ),
          ),

          // ── 5. Best Sellers ──
          SliverToBoxAdapter(
            child: _SectionWrapper(
              title: 'Bán chạy',
              child: _BestSellersRow(categoryIds: _getAllCategoryIds()),
            ),
          ),

          // ── 6. New Arrivals ──
          SliverToBoxAdapter(
            child: _SectionWrapper(
              title: 'Mới nhất',
              child: _NewArrivalsRow(categoryIds: _getAllCategoryIds()),
            ),
          ),

          // ── 7. All Products Section Title + Sort ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Tất cả sản phẩm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _SortDropdown(
                    value: _sortBy,
                    onChanged: (v) {
                      final asc = v == 'base_price';
                      _onSortChange(v, asc);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── 8. Product Grid ──
          if (_isLoading)
            const SliverToBoxAdapter(child: _ProductGridShimmer())
          else if (_allProducts.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(
                onReset: () {
                  setState(() {
                    _selectedSubId = null;
                    _selectedGrandchildId = null;
                  });
                  _loadProducts();
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i >= _allProducts.length) {
                      return const ProductCardShimmer();
                    }
                    final product = _allProducts[i];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.push('/products/${product.id}'),
                    );
                  },
                  childCount: _allProducts.length +
                      (_isLoadingMore ? 2 : 0),
                ),
              ),
            ),

          // Load more indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── 9. Filter & Sort FAB ──
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showFilterSheet(context),
        backgroundColor: _surfaceColor,
        child: const Icon(Icons.tune_rounded, color: _textPrimary),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        currentSort: _sortBy,
        onSortChanged: (sortBy, asc) {
          _onSortChange(sortBy, asc);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Sticky Header
// ═════════════════════════════════════════════

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.title,
    required this.cartCount,
    required this.onBack,
    required this.onSearch,
    required this.onCart,
  });

  final String title;
  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: _textPrimary),
          onPressed: onSearch,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined,
                  color: _textPrimary),
              onPressed: onCart,
            ),
            if (cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4757),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    cartCount > 99 ? '99+' : '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// Hero Banner
// ═════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.banners});

  final List<BannerModel> banners;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banners.first.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (banners.first.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banners.first.subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Subcategory Bar
// ═════════════════════════════════════════════

class _SubcategoryBar extends StatelessWidget {
  const _SubcategoryBar({
    required this.subcategories,
    required this.selectedId,
    required this.grandchildSelected,
    required this.onSubcategoryTap,
    required this.onGrandchildTap,
  });

  final List<MenuItemModel> subcategories;
  final String? selectedId;
  final String? grandchildSelected;
  final void Function(String) onSubcategoryTap;
  final void Function(String) onGrandchildTap;

  @override
  Widget build(BuildContext context) {
    final selectedSub = selectedId != null
        ? subcategories.where((s) => s.id == selectedId).firstOrNull
        : null;
    final grandchildren = selectedSub?.children ?? [];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subcategories.length + 2,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final isAll = selectedId == null;
                  return _Chip(
                    label: 'Tất cả',
                    selected: isAll,
                    onTap: () {
                      if (!isAll) onSubcategoryTap('all');
                    },
                  );
                }
                if (i == subcategories.length + 1) return const SizedBox();
                final sub = subcategories[i - 1];
                final isSel = sub.id == selectedId;
                return _Chip(
                  label: sub.name,
                  selected: isSel || (selectedId == null && i == 1),
                  onTap: () => onSubcategoryTap(sub.id),
                );
              },
            ),
          ),
          if (grandchildren.isNotEmpty && selectedId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: grandchildren.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final gc = grandchildren[i];
                  final isSel = gc.id == grandchildSelected;
                  return _Chip(
                    label: gc.name,
                    selected: isSel,
                    small: true,
                    onTap: () => onGrandchildTap(gc.id),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    this.small = false,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _textPrimary : _textSecondary,
            fontSize: small ? 11 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Section Wrapper (glassmorphism)
// ═════════════════════════════════════════════

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Featured Products Row
// ═════════════════════════════════════════════

class _FeaturedRow extends ConsumerWidget {
  const _FeaturedRow({required this.categoryIds});

  final List<String> categoryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return productsAsync.when(
      loading: () => const _HorizontalShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: _GlassProductCard(
                product: products[i],
                onTap: () =>
                    context.push('/products/${products[i].id}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════
// Best Sellers Row
// ═════════════════════════════════════════════

class _BestSellersRow extends ConsumerWidget {
  const _BestSellersRow({required this.categoryIds});

  final List<String> categoryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(bestSellersProvider);

    return productsAsync.when(
      loading: () => const _HorizontalShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: _GlassProductCard(
                product: products[i],
                onTap: () =>
                    context.push('/products/${products[i].id}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════
// New Arrivals Row
// ═════════════════════════════════════════════

class _NewArrivalsRow extends ConsumerWidget {
  const _NewArrivalsRow({required this.categoryIds});

  final List<String> categoryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(newArrivalsProvider);

    return productsAsync.when(
      loading: () => const _HorizontalShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: _GlassProductCard(
                product: products[i],
                onTap: () =>
                    context.push('/products/${products[i].id}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════
// Glassmorphism Product Card
// ═════════════════════════════════════════════

class _GlassProductCard extends StatelessWidget {
  const _GlassProductCard({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = product.basePrice;
    final originalPrice = product.compareAtPrice;
    final hasDiscount = originalPrice != null && originalPrice > price;
    final discountPercent = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: product.primaryImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(product.primaryImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.primaryImageUrl == null
                        ? const Center(
                            child: Icon(Icons.image_outlined,
                                color: _textSecondary, size: 32),
                          )
                        : null,
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              color: Color(0xFF38EF7D),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${originalPrice.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                color: _textSecondary.withValues(alpha: 0.5),
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasDiscount)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Sort Dropdown
// ═════════════════════════════════════════════

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: _surfaceColor,
          icon: const Icon(Icons.expand_more, color: _textSecondary, size: 18),
          style: const TextStyle(color: _textSecondary, fontSize: 12),
          items: const [
            DropdownMenuItem(
                value: 'created_at',
                child: Text('Mới nhất', style: TextStyle(color: _textPrimary))),
            DropdownMenuItem(
                value: 'total_sold',
                child:
                    Text('Bán chạy', style: TextStyle(color: _textPrimary))),
            DropdownMenuItem(
                value: 'base_price',
                child: Text('Giá thấp', style: TextStyle(color: _textPrimary))),
            DropdownMenuItem(
                value: 'average_rating',
                child:
                    Text('Đánh giá', style: TextStyle(color: _textPrimary))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Filter Bottom Sheet
// ═════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  final String currentSort;
  final void Function(String sortBy, bool ascending) onSortChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sortBy;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sắp xếp theo',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _SortOption(
            label: 'Mới nhất',
            selected: _sortBy == 'created_at',
            onTap: () => setState(() {
              _sortBy = 'created_at';
              _ascending = false;
            }),
          ),
          _SortOption(
            label: 'Bán chạy nhất',
            selected: _sortBy == 'total_sold',
            onTap: () => setState(() {
              _sortBy = 'total_sold';
              _ascending = false;
            }),
          ),
          _SortOption(
            label: 'Giá thấp đến cao',
            selected: _sortBy == 'base_price' && _ascending,
            onTap: () => setState(() {
              _sortBy = 'base_price';
              _ascending = true;
            }),
          ),
          _SortOption(
            label: 'Giá cao đến thấp',
            selected: _sortBy == 'base_price' && !_ascending,
            onTap: () => setState(() {
              _sortBy = 'base_price';
              _ascending = false;
            }),
          ),
          _SortOption(
            label: 'Đánh giá cao nhất',
            selected: _sortBy == 'average_rating',
            onTap: () => setState(() {
              _sortBy = 'average_rating';
              _ascending = false;
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onSortChanged(_sortBy, _ascending),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: _textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFF38EF7D)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF38EF7D)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Color(0xFF0E0E10))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? _textPrimary : _textSecondary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Shimmer / Loading States
// ═════════════════════════════════════════════

class _HorizontalShimmer extends StatelessWidget {
  const _HorizontalShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
        ),
      ),
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: _textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có sản phẩm trong danh mục này',
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: _textPrimary,
            ),
            child: const Text('Xem tất cả'),
          ),
        ],
      ),
    );
  }
}
