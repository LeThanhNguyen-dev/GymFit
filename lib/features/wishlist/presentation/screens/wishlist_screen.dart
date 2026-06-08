import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/wishlist_model.dart';
import '../../providers/wishlist_providers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistItemsProvider);
    final count = ref.watch(wishlistCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Badge(label: Text('$count'))),
          ),
        ],
      ),
      body: wishlistState.when(
        loading: () => const _WishlistLoading(),
        error: (error, _) => _WishlistError(
          message: error.toString(),
          onRetry: () =>
              ref.read(wishlistItemsProvider.notifier).loadWishlist(),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyWishlist();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(wishlistItemsProvider.notifier).loadWishlist(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _WishlistCard(
                item: items[index],
                onRemove: () => ref
                    .read(wishlistItemsProvider.notifier)
                    .removeFromWishlist(items[index].productId),
                onAddToCart: () async {
                  final product = items[index].product;
                  final variant = product?.variants.firstOrNull;
                  if (product == null || variant == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sản phẩm chưa có phiên bản để thêm.'),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(cartItemsProvider.notifier)
                      .addToCart(product.id, variant.id, 1);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm vào giỏ hàng.')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
  });

  final WishlistItemModel item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final imageUrl = product?.primaryImageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl == null
                      ? ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported_outlined),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'Sản phẩm',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(formatCurrency(_displayPrice(product))),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onAddToCart,
                    child: const Text('Thêm vào giỏ'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _displayPrice(ProductModel? product) {
    if (product == null) return 0;
    return product.variants.firstOrNull?.price ?? product.basePrice;
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64),
          SizedBox(height: 16),
          Text('Chưa có sản phẩm yêu thích'),
        ],
      ),
    );
  }
}

class _WishlistLoading extends StatelessWidget {
  const _WishlistLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _WishlistError extends StatelessWidget {
  const _WishlistError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
