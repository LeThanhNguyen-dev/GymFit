import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/providers/product_providers.dart';
import '../../../products/presentation/widgets/product_card.dart';

class RecommendedGrid extends ConsumerWidget {
  const RecommendedGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendedProductsProvider);
    return async.when(
      data: (products) => _Grid(products: products),
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.64,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(product: products[i], onTap: () => context.push('/products/${products[i].id}')),
          childCount: products.length,
        ),
      ),
    );
  }
}
