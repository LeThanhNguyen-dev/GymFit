import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../../cart/providers/cart_providers.dart';
import '../../../checkout/data/models/checkout_model.dart';
import '../../../wishlist/providers/wishlist_providers.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_providers.dart';
import '../../providers/comparison_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  ProductVariantModel? _selectedVariant;
  int _quantity = 1;
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final isInWishlist = ref.watch(isInWishlistProvider(widget.productId));
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: productAsync.when(
        loading: () => const _DetailLoading(),
        error: (e, _) => _DetailError(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Sản phẩm không tồn tại.'));
          }
          // Set default variant on first load
          if (_selectedVariant == null && product.variants.isNotEmpty) {
            _selectedVariant = product.variants.first;
          }
          return _buildContent(context, product, isInWishlist, cartCount);
        },
      ),
      bottomNavigationBar: productAsync.whenOrNull(
        data: (product) {
          if (product == null) return null;
          return ProductDetailBottomBar(
            product: product,
            selectedVariant: _selectedVariant,
            quantity: _quantity,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductModel product,
    bool isInWishlist,
    int cartCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPrice = _selectedVariant?.price ?? product.basePrice;
    final selectedStock = _selectedVariant?.stock ?? 0;
    final isOutOfStock = selectedStock == 0;

    return CustomScrollView(
      slivers: [
        // ── Image Carousel + AppBar ─────────────────────────────────────
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  onPressed: () {
                    final isAdded = ref.read(comparisonProvider.notifier).addProduct(product);
                    if (isAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm vào danh sách so sánh')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể thêm (tối đa 3 sản phẩm hoặc đã tồn tại)')),
                      );
                    }
                  },
                ),
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
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
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
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isInWishlist
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isInWishlist),
                  color: isInWishlist ? Colors.red : null,
                ),
              ),
              onPressed: () {
                ref
                    .read(wishlistItemsProvider.notifier)
                    .toggleWishlist(widget.productId);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: product.images.isEmpty
                ? Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.white54,
                    ),
                  )
                : _ImageCarousel(
                    images: product.images,
                    selectedIndex: _selectedImageIndex,
                    onPageChanged: (i) =>
                        setState(() => _selectedImageIndex = i),
                  ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Name & Rating ─────────────────────────────
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.averageRating > 0) ...[
                      ...List.generate(5, (i) {
                        return Icon(
                          i < product.averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: Colors.amber[600],
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        ' (${product.totalReviews} đánh giá)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (product.totalSold > 0)
                      Text(
                        '• Đã bán ${product.totalSold}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Price ─────────────────────────────────────────────
                Text(
                  formatCurrency(selectedPrice),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),

                // ── Variant Selector ──────────────────────────────────
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _VariantSelector(
                    variants: product.variants,
                    selectedVariant: _selectedVariant,
                    basePrice: product.basePrice,
                    onSelect: (v) {
                      setState(() {
                        _selectedVariant = v;
                        _quantity = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (!isOutOfStock)
                    Text(
                      'Còn $selectedStock sản phẩm',
                      style: TextStyle(
                        color: selectedStock <= 5
                            ? colorScheme.error
                            : colorScheme.outline,
                        fontSize: 13,
                      ),
                    )
                  else
                    Text(
                      'Hết hàng',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // ── Quantity ──────────────────────────────────────────
                if (!isOutOfStock) ...[
                  Row(
                    children: [
                      Text(
                        'Số lượng: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuantitySelector(
                        quantity: _quantity,
                        maxQuantity: selectedStock,
                        onChanged: (q) => setState(() => _quantity = q),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),

                // ── Description ───────────────────────────────────────
                const SizedBox(height: 12),
                Text(
                  'Mô tả sản phẩm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (product.description != null &&
                    product.description!.isNotEmpty)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _descriptionExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      product.description!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    secondChild: Text(
                      product.description!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  )
                else
                  Text(
                    'Chưa có mô tả sản phẩm.',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                if (product.description != null &&
                    product.description!.length > 200)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _descriptionExpanded = !_descriptionExpanded;
                      });
                    },
                    child: Text(_descriptionExpanded ? 'Thu gọn' : 'Xem thêm'),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // ── Brand & Category ──────────────────────────────────
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.brand != null)
                      _InfoChip(
                        icon: Icons.shield_outlined,
                        label: product.brand!.name,
                      ),
                    if (product.category != null)
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: product.category!.name,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Related Products ──────────────────────────────────
                if (product.category != null) ...[
                  Text(
                    'Sản phẩm tương tự',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RelatedProductsRow(
                    productId: product.id,
                    categoryId: product.category!.id,
                  ),
                ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image Carousel ────────────────────────────────────────────────────────────

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({
    required this.images,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final List<ProductImageModel> images;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: widget.onPageChanged,
          itemCount: widget.images.length,
          itemBuilder: (context, i) => GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black.withValues(alpha: 0.9),
                  pageBuilder: (context, _, __) {
                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        iconTheme: const IconThemeData(color: Colors.white),
                        elevation: 0,
                      ),
                      body: PageView.builder(
                        itemCount: widget.images.length,
                        controller: PageController(initialPage: i),
                        itemBuilder: (context, j) => InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              widget.images[j].url,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            child: Image.network(
              widget.images[i].url,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 60),
              ),
            ),
          ),
        ),
        // Dot indicators
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: widget.selectedIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.selectedIndex == i
                      ? Colors.white
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Variant Selector ──────────────────────────────────────────────────────────

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedVariant,
    required this.onSelect,
    required this.basePrice,
  });

  final List<ProductVariantModel> variants;
  final ProductVariantModel? selectedVariant;
  final ValueChanged<ProductVariantModel> onSelect;
  final num basePrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phiên bản:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((v) {
            final isSelected = selectedVariant?.id == v.id;
            final isOutOfStock = v.stock == 0;
            return GestureDetector(
              onTap: isOutOfStock ? null : () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isOutOfStock
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.optionDisplay.isNotEmpty
                          ? v.optionDisplay
                          : v.sku.isNotEmpty
                          ? v.sku
                          : 'Loại ${variants.indexOf(v) + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isOutOfStock
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        decoration: isOutOfStock
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (v.price != null && v.price != basePrice) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${v.price! > basePrice ? '+' : '-'}${formatCurrency(v.price! > basePrice ? v.price! - basePrice : basePrice - v.price!)})',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Quantity Selector ─────────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          onPressed: quantity <= 1 ? null : () => onChanged(quantity - 1),
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: quantity >= maxQuantity
              ? null
              : () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

// ── Related Products Row ──────────────────────────────────────────────────────

class _RelatedProductsRow extends ConsumerWidget {
  const _RelatedProductsRow({
    required this.productId,
    required this.categoryId,
  });

  final String productId;
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = RelatedProductsArgs(
      productId: productId,
      categoryId: categoryId,
    );
    final relatedAsync = ref.watch(relatedProductsProvider(args));

    return SizedBox(
      height: 210,
      child: relatedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox.shrink(),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Không có sản phẩm tương tự.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, s) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 140,
              child: GestureDetector(
                onTap: () => context.push('/products/${products[i].id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: products[i].primaryImageUrl != null
                            ? Image.network(
                                products[i].primaryImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      products[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatCurrency(products[i].basePrice),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Add to Cart Bottom Bar ─────────────────────────────────────────────────────

class ProductDetailBottomBar extends ConsumerWidget {
  const ProductDetailBottomBar({
    super.key,
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = selectedVariant?.stock ?? 0;
    final isOutOfStock = stock <= 0 || quantity > stock;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () async {
                        if (selectedVariant == null) return;
                        try {
                          await ref
                              .read(cartItemsProvider.notifier)
                              .addToCart(
                                product.id,
                                selectedVariant!.id,
                                quantity,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thêm vào giỏ hàng!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Thêm vào giỏ'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () {
                        if (selectedVariant == null) return;
                        final item = CartItemModel(
                          id: 'buy_now_${selectedVariant!.id}',
                          userId: '',
                          productId: product.id,
                          variantId: selectedVariant!.id,
                          quantity: quantity,
                          product: product,
                          variant: selectedVariant,
                        );
                        final subtotal = item.itemTotal;
                        context.push(
                          '/checkout',
                          extra: CheckoutData(
                            cartItems: [item],
                            source: CheckoutSource.buyNow,
                            subtotal: subtotal,
                            discountAmount: 0,
                            total: subtotal,
                          ),
                        );
                      },
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Mua ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
