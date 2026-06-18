import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/products/providers/product_providers.dart';
import '../../../../features/products/presentation/widgets/product_card.dart';

enum ProductListType { featured, newArrivals, recommended }

class ProductListHorizontal extends ConsumerWidget {
  const ProductListHorizontal({
    super.key,
    required this.type,
  });

  final ProductListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = switch (type) {
      ProductListType.featured => ref.watch(featuredProductsProvider),
      ProductListType.newArrivals => ref.watch(newArrivalsProvider),
      ProductListType.recommended => ref.watch(recommendedProductsProvider),
    };

    return SizedBox(
      height: 230,
      child: asyncProducts.when(
        loading: () => _ShimmerList(),
        error: (_, _) => const SizedBox.shrink(),
        data: (products) {
          if (products.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 160,
              child: ProductCard(
                product: products[i],
                onTap: () => context.push('/products/${products[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => const SizedBox(
        width: 160,
        child: ProductCardShimmer(),
      ),
    );
  }
}
