import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../products/data/models/product_model.dart';
import '../../providers/ai_recommendation_provider.dart';

class RecommendationSection extends ConsumerWidget {
  const RecommendationSection({
    super.key,
    required this.title,
    this.productId,
    required this.type,
    this.onProductTap,
  });

  final String title;
  final String? productId;
  final String type;
  final ValueChanged<ProductModel>? onProductTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = switch (type) {
      'similar' => similarProductsProvider(productId ?? ''),
      'also_bought' => alsoBoughtProvider(productId ?? ''),
      _ => personalizedProvider,
    };
    final products = ref.watch(provider);

    return products.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _ProductMiniCard(
                  product: items[index],
                  onTap: () => onProductTap?.call(items[index]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({required this.product, this.onTap});

  final ProductModel product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: product.primaryImageUrl == null
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      )
                    : Image.network(
                        product.primaryImageUrl!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${product.basePrice.round()}d'),
          ],
        ),
      ),
    );
  }
}
