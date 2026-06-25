import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../wishlist/providers/wishlist_providers.dart';
import '../../data/models/product_model.dart';
import '../../../../core/providers/supabase_providers.dart';

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.soldCount,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final int? soldCount;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  int _realSoldCount = 0;
  bool _hasFetched = false;

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _hasFetched = false;
      _realSoldCount = 0;
      _fetchSoldCount();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSoldCount();
  }

  Future<void> _fetchSoldCount() async {
    if (widget.soldCount != null) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final rows = await client
          .from('order_items')
          .select('quantity')
          .eq('product_id', widget.product.id)
          .eq('store_status', 'delivered');
      final total = rows.fold<int>(0, (sum, r) => sum + ((r as Map)['quantity'] as int? ?? 0));
      if (mounted) setState(() { _realSoldCount = total; _hasFetched = true; });
    } catch (_) {
      if (mounted) setState(() => _hasFetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInWishlist = ref.watch(isInWishlistProvider(widget.product.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displaySold = widget.soldCount ?? (_hasFetched ? _realSoldCount : widget.product.totalSold);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight <= 230;
              final imageHeight = constraints.maxHeight * (compact ? 0.48 : 0.52);
              final infoPadding = compact ? 8.0 : 10.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _ProductImage(imageUrl: widget.product.primaryImageUrl),
                        Positioned(
                          top: AppSpacing.xs,
                          right: AppSpacing.xs,
                          child: _WishlistButton(
                            productId: widget.product.id,
                            isInWishlist: isInWishlist,
                            onToggle: () {
                              ref
                                  .read(wishlistItemsProvider.notifier)
                                  .toggleWishlist(widget.product.id);
                            },
                          ),
                        ),
                        if (widget.product.compareAtPrice != null &&
                            widget.product.compareAtPrice! > widget.product.basePrice)
                          Positioned(
                            top: AppSpacing.xs,
                            left: AppSpacing.xs,
                            child: _Badge(
                              label:
                                  '-${((widget.product.compareAtPrice! - widget.product.basePrice) / widget.product.compareAtPrice! * 100).round()}%',
                              color: colorScheme.error,
                              textColor: colorScheme.onError,
                            ),
                          ),
                        if (widget.product.isFeatured)
                          Positioned(
                            top: widget.product.compareAtPrice != null &&
                                    widget.product.compareAtPrice! > widget.product.basePrice
                                ? 40
                                : AppSpacing.xs,
                            left: AppSpacing.xs,
                            child: _Badge(
                              label: 'Noi bat',
                              color: colorScheme.primary,
                              textColor: colorScheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(infoPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: compact ? 2 : AppSpacing.xxs),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                formatCurrency(widget.product.basePrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: widget.product.compareAtPrice != null &&
                                          widget.product.compareAtPrice! >
                                              widget.product.basePrice
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.product.compareAtPrice != null &&
                                  widget.product.compareAtPrice! > widget.product.basePrice)
                                Text(
                                  formatCurrency(widget.product.compareAtPrice!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.outline,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              if (widget.product.averageRating > 0) ...[
                                Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                                const SizedBox(width: 2),
                                Text(
                                  widget.product.averageRating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${widget.product.totalReviews})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                ),
                              ],
                              if (displaySold > 0) ...[
                                if (widget.product.averageRating > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(width: 3, height: 3, decoration: BoxDecoration(color: colorScheme.outline, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                ],
                                Icon(Icons.shopping_bag_outlined, size: 12, color: colorScheme.outline),
                                const SizedBox(width: 2),
                                Text(
                                  'Đã bán $displaySold',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.fitness_center, size: 48, color: Colors.white54),
        ),
      );
    }
    return Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.fitness_center, size: 48, color: Colors.white54)),
      );
    });
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.productId, required this.isInWishlist, required this.onToggle});
  final String productId;
  final bool isInWishlist;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: isInWishlist ? Colors.red : null,
        ),
        onPressed: onToggle,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        splashRadius: 18,
      ),
    );
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

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(color: colorScheme.surfaceContainerHighest),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4))),
                    SizedBox(height: AppSpacing.xxs),
                    Container(height: 10, width: 80, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4))),
                    Spacer(),
                    Container(height: 10, width: 60, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
