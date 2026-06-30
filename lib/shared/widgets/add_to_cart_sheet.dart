import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/products/data/models/product_model.dart';

class AddToCartSheet extends StatefulWidget {
  const AddToCartSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final ProductModel product;
  final void Function(String variantId, int quantity) onAddToCart;

  static void show(
    BuildContext context, {
    required ProductModel product,
    required void Function(String variantId, int quantity) onAddToCart,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pageHorizontal,
          right: AppSpacing.pageHorizontal,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _SheetBody(product: product, onAddToCart: onAddToCart),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<AddToCartSheet> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.product,
    required this.onAddToCart,
  });

  final ProductModel product;
  final void Function(String variantId, int quantity) onAddToCart;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  ProductVariantModel? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  int get _maxQuantity => _selectedVariant?.quantity ?? 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = widget.product;
    final variants = product.variants;
    final hasMultipleVariants = variants.length > 1;
    final hasVariants = variants.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 64,
                height: 64,
                child: product.primaryImageUrl != null
                    ? Image.network(
                        product.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined, size: 24),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(
                        _selectedVariant?.price ?? product.basePrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: product.compareAtPrice != null &&
                              product.compareAtPrice! > product.basePrice
                          ? colorScheme.error
                          : colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (hasVariants) ...[
          Text(
            hasMultipleVariants ? 'Chọn phân loại' : 'Phân loại',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          hasMultipleVariants
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: variants.map((v) {
                    final selected = _selectedVariant?.id == v.id;
                    final outOfStock = v.quantity <= 0;
                    return GestureDetector(
                      onTap: outOfStock
                          ? null
                          : () => setState(() {
                                _selectedVariant = v;
                                _quantity = 1;
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          v.name ?? v.optionDisplay,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: outOfStock
                                ? colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)
                                : selected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                            decoration: outOfStock
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    variants.first.name ?? variants.first.optionDisplay,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_selectedVariant != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lượng', style: theme.textTheme.labelLarge),
              Row(
                children: [
                  _QuantityBtn(
                    icon: Icons.remove_rounded,
                    onTap: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantity',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _QuantityBtn(
                    icon: Icons.add_rounded,
                    onTap: _quantity < _maxQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _selectedVariant == null || _maxQuantity <= 0
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onAddToCart(_selectedVariant!.id, _quantity);
                  },
            child: Text(
              _selectedVariant == null || _maxQuantity <= 0
                  ? 'Hết hàng'
                  : 'Thêm vào giỏ hàng',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/products/${product.id}');
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Xem chi tiết sản phẩm'),
          ),
        ),
      ],
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  const _QuantityBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
