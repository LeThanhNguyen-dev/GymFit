import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/add_to_cart_sheet.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/wishlist_model.dart';
import '../../providers/wishlist_providers.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistItemsProvider);
    final count = ref.watch(wishlistCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yêu thích'),
            Text(
              '$count sản phẩm',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (count > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm yêu thích...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: wishlistState.when(
              loading: () => const _WishlistLoading(),
              error: (error, _) => _WishlistError(
                message: error.toString(),
                onRetry: () => ref.read(wishlistItemsProvider.notifier).loadWishlist(),
              ),
              data: (items) {
                final filtered = _searchQuery.isEmpty
                    ? items
                    : items.where((i) {
                        final p = i.product;
                        if (p == null) return false;
                        return p.name.toLowerCase().contains(_searchQuery) ||
                            (p.brand?.name.toLowerCase().contains(_searchQuery) ?? false);
                      }).toList();

                if (items.isEmpty) return const _EmptyWishlist();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 8),
                        Text('Không tìm thấy sản phẩm', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(wishlistItemsProvider.notifier).loadWishlist(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _WishlistCard(
                        item: item,
                        onTap: () {
                          final product = item.product;
                          if (product != null) context.push('/products/${product.id}');
                        },
                        onRemove: () => ref.read(wishlistItemsProvider.notifier).removeFromWishlist(item.productId),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistCard extends ConsumerStatefulWidget {
  const _WishlistCard({required this.item, required this.onTap, required this.onRemove});

  final WishlistItemModel item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  ConsumerState<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends ConsumerState<_WishlistCard> {
  int _realSoldCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSoldCount();
  }

  Future<void> _fetchSoldCount() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final rows = await client
          .from('order_items')
          .select('quantity')
          .eq('product_id', widget.item.productId)
          .eq('store_status', 'delivered');
      final total = rows.fold<int>(
        0,
        (sum, r) => sum + ((r as Map)['quantity'] as int? ?? 0),
      );
      if (mounted) setState(() => _realSoldCount = total);
    } catch (_) {
    }
  }

  void _showAddToCartSheet() {
    final product = widget.item.product;
    if (product == null) return;

    AddToCartSheet.show(
      context,
      product: product,
      onAddToCart: (variantId, quantity) async {
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(cartItemsProvider.notifier).addToCart(
              product.id,
              variantId,
              quantity,
            );
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã thêm vào giỏ hàng.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item.product;
    final imageUrl = product?.primaryImageUrl;
    final isInWishlist = ref.watch(isInWishlistProvider(widget.item.productId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displaySold =
        _realSoldCount > 0 ? _realSoldCount : (product?.totalSold ?? 0);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            height: 136,
            child: Row(
              children: [
                SizedBox(
                  width: 136,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProductImage(imageUrl: imageUrl),
                      if (product?.compareAtPrice != null &&
                          product!.compareAtPrice! > product.basePrice)
                        Positioned(
                          top: AppSpacing.xxs,
                          left: AppSpacing.xxs,
                          child: _Badge(
                            label:
                                '-${((product.compareAtPrice! - product.basePrice) / product.compareAtPrice! * 100).round()}%',
                            color: colorScheme.error,
                            textColor: colorScheme.onError,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if ((product?.averageRating ?? 0) > 0) ...[
                              Icon(Icons.star_rounded, size: 13, color: Colors.amber[600]),
                              const SizedBox(width: 2),
                              Text(
                                product!.averageRating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${product.totalReviews})',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                              ),
                            ],
                            if (displaySold > 0) ...[
                              if ((product?.averageRating ?? 0) > 0) ...[
                                const SizedBox(width: 6),
                                Container(width: 3, height: 3, decoration: BoxDecoration(color: colorScheme.outline, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                              ],
                              Icon(Icons.shopping_bag_outlined, size: 12, color: colorScheme.outline),
                              const SizedBox(width: 2),
                              Text(
                                'Đã bán $displaySold',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatCurrency(_displayPrice(product)),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: IconButton(
                                onPressed: _showAddToCartSheet,
                                icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 15,
                                tooltip: 'Thêm vào giỏ',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    _AnimatedWishlistButton(
                      isInWishlist: isInWishlist,
                      onToggle: () =>
                          ref.read(wishlistItemsProvider.notifier).toggleWishlist(widget.item.productId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _displayPrice(ProductModel? product) {
    if (product == null) return 0;
    return product.variants.firstOrNull?.price ?? product.basePrice;
  }
}

class _AnimatedWishlistButton extends StatefulWidget {
  const _AnimatedWishlistButton({required this.isInWishlist, required this.onToggle});
  final bool isInWishlist;
  final VoidCallback onToggle;

  @override
  State<_AnimatedWishlistButton> createState() => _AnimatedWishlistButtonState();
}

class _AnimatedWishlistButtonState extends State<_AnimatedWishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        margin: const EdgeInsets.only(top: 6, right: 6),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(
            widget.isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: widget.isInWishlist ? Colors.red : null,
          ),
          onPressed: () {
            _controller.forward(from: 0);
            widget.onToggle();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          splashRadius: 16,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.fitness_center, size: 32, color: Colors.white54),
        ),
      );
    }
    return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.fitness_center, size: 32, color: Colors.white54)),
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Chưa có sản phẩm yêu thích', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Hãy thêm sản phẩm bạn yêu thích vào danh sách', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Khám phá ngay'),
          ),
        ],
      ),
    );
  }
}

class _WishlistLoading extends StatelessWidget {
  const _WishlistLoading();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 136,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
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
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
