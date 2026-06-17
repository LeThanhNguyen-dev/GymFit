import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/providers/cart_providers.dart';
import '../../../../core/widgets/navbar.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/providers/brand_providers.dart';
import '../../../products/providers/category_providers.dart';
import '../../../products/providers/product_providers.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../providers/banner_providers.dart';
import '../../data/models/banner_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(bestSellersProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(categoryListProvider);
          ref.invalidate(brandListProvider);
          ref.invalidate(bannerListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GymFit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () => context.push('/cart'),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
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
                const SizedBox(width: 4),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search Bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tìm kiếm sản phẩm...',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Navigation Bar ──────────────────────────────────────
                  NavBar(
                    onCategorySelected: (slug) {
                      context.push('/products?category=$slug');
                    },
                  ),

                  // ── Banner Carousel ──────────────────────────────────────
                  const _BannerCarousel(),

                  // ── Categories ──────────────────────────────────────────
                  const _SectionTitle(title: 'Danh mục'),
                  const _CategoriesSection(),

                  // ── Recommended Products ─────────────────────────────────
                  _SectionTitle(
                    title: 'Dành riêng cho bạn',
                    onSeeAll: () => context.push('/products'),
                  ),
                  const _HorizontalProductList(
                    providerType: _ProductProviderType.recommended,
                  ),

                  // ── Featured Products ────────────────────────────────────
                  _SectionTitle(
                    title: 'Sản phẩm nổi bật',
                    onSeeAll: () => context.push('/products'),
                  ),
                  const _HorizontalProductList(
                    providerType: _ProductProviderType.featured,
                  ),

                  // ── Brands ───────────────────────────────────────────────
                  const _SectionTitle(title: 'Thương hiệu'),
                  const _BrandsSection(),

                  // ── Best Sellers ─────────────────────────────────────────
                  _SectionTitle(
                    title: 'Bán chạy nhất',
                    onSeeAll: () => context.push('/products'),
                  ),
                  const _BestSellersGrid(),

                  // ── New Arrivals ──────────────────────────────────────────
                  _SectionTitle(
                    title: 'Hàng mới về',
                    onSeeAll: () => context.push('/products'),
                  ),
                  const _HorizontalProductList(
                    providerType: _ProductProviderType.newArrivals,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner Carousel ──────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  List<BannerModel> _banners = [];

  @override
  void initState() {
    super.initState();
    // Auto scroll
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted || _banners.isEmpty) return;
    final next = (_current + 1) % _banners.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final bannerAsync = ref.watch(bannerListProvider);
        return bannerAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox(height: 180),
          data: (banners) {
            _banners = banners;
            if (_banners.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: _banners.length,
                    itemBuilder: (context, i) {
                      final banner = _banners[i];
                      return GestureDetector(
                        onTap: banner.targetRoute != null
                            ? () => context.push(banner.targetRoute!)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: banner.startColor != null && banner.endColor != null
                                ? LinearGradient(
                                    colors: [banner.startColor!, banner.endColor!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: banner.startColor ?? Theme.of(context).colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (banner.startColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 40,
                                bottom: -30,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (banner.subtitle != null) ...[
                                            Text(
                                              banner.subtitle!,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          Text(
                                            banner.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Mua ngay',
                                              style: TextStyle(
                                                color: banner.startColor ?? Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (banner.imageUrl != null)
                                      Image.network(
                                        banner.imageUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.contain,
                                      )
                                    else if (banner.icon != null)
                                      Icon(
                                        banner.icon,
                                        size: 80,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


// ── Categories Section ───────────────────────────────────────────────────────

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return SizedBox(
      height: 96,
      child: categoriesAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          separatorBuilder: (_, s) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _CategoryShimmer(),
        ),
        error: (e, _) => const SizedBox.shrink(),
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, s) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _CategoryChip(category: categories[i]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/products', extra: {'categoryId': category.id}),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: category.imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Icon(
                        Icons.category_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Container(width: 48, height: 10, color: color),
      ],
    );
  }
}

// ── Brands Section ───────────────────────────────────────────────────────────

class _BrandsSection extends ConsumerWidget {
  const _BrandsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandListProvider);

    return SizedBox(
      height: 76,
      child: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox.shrink(),
        data: (brands) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: brands.length,
          separatorBuilder: (_, s) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _BrandChip(brand: brands[i]),
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});
  final BrandModel brand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products', extra: {'brandId': brand.id}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: brand.logoUrl != null
            ? Image.network(brand.logoUrl!, height: 36, fit: BoxFit.contain)
            : Text(
                brand.name,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// ── Horizontal Product List ───────────────────────────────────────────────────

enum _ProductProviderType { featured, newArrivals, recommended }

class _HorizontalProductList extends ConsumerWidget {
  const _HorizontalProductList({required this.providerType});
  final _ProductProviderType providerType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = switch (providerType) {
      _ProductProviderType.featured => ref.watch(featuredProductsProvider),
      _ProductProviderType.newArrivals => ref.watch(newArrivalsProvider),
      _ProductProviderType.recommended => ref.watch(recommendedProductsProvider),
    };

    return SizedBox(
      height: 230,
      child: asyncProducts.when(
        loading: () => _buildShimmerList(),
        error: (e, _) => const SizedBox.shrink(),
        data: (products) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          separatorBuilder: (_, s) => const SizedBox(width: 12),
          itemBuilder: (context, i) => SizedBox(
            width: 160,
            child: ProductCard(
              product: products[i],
              onTap: () => context.push('/products/${products[i].id}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, s) => const SizedBox(width: 12),
      itemBuilder: (_, i) =>
          const SizedBox(width: 160, child: ProductCardShimmer()),
    );
  }
}

// ── Best Sellers Grid ─────────────────────────────────────────────────────────

class _BestSellersGrid extends ConsumerWidget {
  const _BestSellersGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestSellersAsync = ref.watch(bestSellersProvider);

    return bestSellersAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (_, i) => const ProductCardShimmer(),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (products) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length.clamp(0, 4),
          itemBuilder: (context, i) => ProductCard(
            product: products[i],
            onTap: () => context.push('/products/${products[i].id}'),
          ),
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }
}
