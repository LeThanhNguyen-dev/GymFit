import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/menu_providers.dart';
import '../../../../core/widgets/navbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gym_fit_logo.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../products/providers/product_providers.dart';
import '../../../products/providers/category_providers.dart';
import '../../../products/providers/brand_providers.dart';
import '../../providers/banner_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/categories_section.dart';
import '../widgets/brands_section.dart';
import '../widgets/shortcut_grid.dart';
import '../widgets/voucher_strip.dart';
import '../widgets/flash_sale_section.dart';
import '../widgets/recommended_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: CustomScrollView(
          slivers: [
            _AppBar(cartCount: cartCount),
            SliverToBoxAdapter(child: _HomeBody()),
            RecommendedGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
    ref.invalidate(flashSaleProductsProvider);
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
      pinned: true,
      floating: false,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GymFitLogo(size: 18, color: colorScheme.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'GymFit',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Tìm kiếm...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                  onPressed: () => context.push('/cart'),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4, top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text(cartCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
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
        NavBar(
          onCategorySelected: (id) {
            context.push('/products', extra: {'categoryId': id});
          },
        ),
        const SizedBox(height: 12),
        const BannerCarousel(),
        const ShortcutGrid(),
        const VoucherStrip(),
        const FlashSaleSection(),
        const CategoriesSection(),
        const BrandsSection(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Row(
            children: [
              Text('Gợi ý hôm nay', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/products'),
                child: const Text('Xem thêm'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
