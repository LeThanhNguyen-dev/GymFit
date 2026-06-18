import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/products/providers/product_providers.dart';
import '../../../../features/products/presentation/widgets/product_card.dart';
import '../../presentation/widgets/section_title.dart';

class BestSellersGrid extends ConsumerWidget {
  const BestSellersGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestSellersAsync = ref.watch(bestSellersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Bán chạy nhất',
          onSeeAll: () => context.push('/products'),
        ),
        bestSellersAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (_, _) => const ProductCardShimmer(),
          ),
        ),
          error: (_, _) => const SizedBox.shrink(),
          data: (products) {
            if (products.isEmpty) return const SizedBox.shrink();
            final display =
                products.length > 4 ? products.sublist(0, 4) : products;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: display.length,
                itemBuilder: (context, i) => ProductCard(
                  product: display[i],
                  onTap: () => context.push('/products/${display[i].id}'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
