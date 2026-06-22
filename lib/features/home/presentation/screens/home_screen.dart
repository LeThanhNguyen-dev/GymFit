import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/menu_providers.dart';
import '../../../../core/widgets/navbar.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../products/providers/product_providers.dart';
import '../../../products/providers/category_providers.dart';
import '../../../products/providers/brand_providers.dart';
import '../../providers/banner_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/categories_section.dart';
import '../widgets/brands_section.dart';
import '../widgets/section_title.dart';
import '../widgets/product_list_horizontal.dart';
import '../widgets/best_sellers_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: CustomScrollView(
          slivers: [
            _AppBar(cartCount: cartCount),
            SliverToBoxAdapter(child: _HomeBody()),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(featuredProductsProvider);
    ref.invalidate(bestSellersProvider);
    ref.invalidate(newArrivalsProvider);
    ref.invalidate(recommendedProductsProvider);
    ref.invalidate(categoryListProvider);
    ref.invalidate(completeMenuProvider);
    ref.invalidate(brandListProvider);
    ref.invalidate(bannerListProvider);
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.cartCount});

  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      toolbarHeight: 72,
      title: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'GymFit',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Search bar
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tìm kiếm sản phẩm...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Cart button with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () => context.push('/cart'),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
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
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Nav Bar
        NavBar(
          onCategorySelected: (slug) {
            context.push('/products?category=$slug');
          },
        ),

        // Hero Banner Carousel (includes banners + services)
        const BannerCarousel(),

        const SizedBox(height: 4),

        // Categories Grid
        const CategoriesSection(),

        // Featured Brands
        const BrandsSection(),

        // Recommended Products
        SectionTitle(
          title: 'Dành riêng cho bạn',
          onSeeAll: () => context.push('/products'),
        ),
        const ProductListHorizontal(type: ProductListType.recommended),

        // Featured Products
        SectionTitle(
          title: 'Sản phẩm nổi bật',
          onSeeAll: () => context.push('/products'),
        ),
        const ProductListHorizontal(type: ProductListType.featured),

        // Best Sellers
        const BestSellersGrid(),

        // New Arrivals
        SectionTitle(
          title: 'Hàng mới về',
          onSeeAll: () => context.push('/products'),
        ),
        const ProductListHorizontal(type: ProductListType.newArrivals),

        const SizedBox(height: 32),
      ],
    );
  }
}
