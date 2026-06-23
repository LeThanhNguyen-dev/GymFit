import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../checkout/data/models/checkout_model.dart';
import '../../../voucher/providers/voucher_provider.dart';
import '../../data/models/cart_model.dart';
import '../../providers/cart_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Set<String> _selectedItemIds = <String>{};

  void _syncSelection(List<CartItemModel> items) {
    final existingIds = items.map((item) => item.id).toSet();
    _selectedItemIds.removeWhere((id) => !existingIds.contains(id));
    if (_selectedItemIds.isEmpty && items.isNotEmpty) {
      _selectedItemIds.addAll(existingIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartItemsProvider);
    final voucher = ref.watch(appliedVoucherProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: cartState.when(
        loading: () => const _CartLoading(),
        error: (error, _) => _CartError(
          message: error.toString(),
          onRetry: () => ref.read(cartItemsProvider.notifier).loadCart(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyCart(
              onContinue: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            );
          }

          _syncSelection(items);
          final selectedItems = items
              .where((item) => _selectedItemIds.contains(item.id))
              .toList();
          final selectedSubtotal = selectedItems.fold<double>(
            0,
            (sum, item) => sum + item.itemTotal,
          );
          final discount = voucher?.calculateDiscount(selectedSubtotal) ?? 0;
          final total = (selectedSubtotal - discount).clamp(0, double.infinity);
          final summary = CartSummary(
            subtotal: selectedSubtotal,
            itemCount: selectedItems.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            ),
          );
          final hasStockIssue = selectedItems.any((item) => !item.isInStock);

          return RefreshIndicator(
            onRefresh: () => ref.read(cartItemsProvider.notifier).loadCart(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SelectionHeader(
                    selectedCount: selectedItems.length,
                    totalCount: items.length,
                    allSelected: selectedItems.length == items.length,
                    onChanged: (selected) {
                      setState(() {
                        _selectedItemIds.clear();
                        if (selected) {
                          _selectedItemIds.addAll(items.map((item) => item.id));
                        }
                      });
                    },
                  ),
                ),
                SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => _CartItemTile(
                    item: items[index],
                    isSelected: _selectedItemIds.contains(items[index].id),
                    onSelectionChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedItemIds.add(items[index].id);
                        } else {
                          _selectedItemIds.remove(items[index].id);
                        }
                      });
                    },
                    onQuantityChanged: (quantity) => ref
                        .read(cartItemsProvider.notifier)
                        .updateQuantity(items[index].id, quantity),
                    onRemove: () {
                      setState(() => _selectedItemIds.remove(items[index].id));
                      ref
                          .read(cartItemsProvider.notifier)
                          .removeItem(items[index].id);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CartSummarySection(
                    summary: summary,
                    discount: discount,
                    total: total.toDouble(),
                    voucherCode: voucher?.code,
                    hasStockIssue: hasStockIssue,
                    hasSelection: selectedItems.isNotEmpty,
                    onVoucherTap: () =>
                        context.push('/vouchers', extra: selectedSubtotal),
                    onRemoveVoucher: () {
                      ref
                          .read(appliedVoucherProvider.notifier)
                          .setVoucher(null);
                    },
                    onCheckout: () async {
                      if (selectedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng chọn sản phẩm để thanh toán.'),
                          ),
                        );
                        return;
                      }

                      final stockIssues = await ref
                          .read(cartItemsProvider.notifier)
                          .checkStock();
                      if (!context.mounted) return;
                      final selectedIssueIds = selectedItems
                          .map((item) => item.id)
                          .toSet();
                      if (stockIssues.any(
                        (item) => selectedIssueIds.contains(item.id),
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Một số sản phẩm đã chọn không đủ tồn kho.',
                            ),
                          ),
                        );
                        return;
                      }

                      context.push(
                        '/checkout',
                        extra: CheckoutData(
                          cartItems: selectedItems,
                          source: CheckoutSource.cart,
                          cartItemIds:
                              selectedItems.map((item) => item.id).toList(),
                          voucher: voucher,
                          subtotal: selectedSubtotal,
                          discountAmount: discount,
                          total: total.toDouble(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.onChanged,
  });

  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Text(
              'Đã chọn $selectedCount/$totalCount sản phẩm',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItemModel item;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final variant = item.variant;
    final imageUrl = variant?.imageUrl ?? product?.primaryImageUrl;
    final stock = variant?.stock ?? 0;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) => onRemove(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => onSelectionChanged(value ?? false),
            ),
            Expanded(
              child: ListTile(
                minVerticalPadding: 12,
                leading: SizedBox.square(
                  dimension: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl == null
                        ? ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          )
                        : Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                title: Text(
                  product?.name ?? 'Sản phẩm',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((variant?.optionDisplay ?? '').isNotEmpty)
                      Text(variant!.optionDisplay),
                    Text(formatCurrency(variant?.price ?? product?.basePrice ?? 0)),
                    if (!item.isInStock)
                      Text(
                        stock == 0
                            ? 'Đã hết hàng'
                            : 'Chỉ còn $stock sản phẩm trong kho',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.formattedTotal,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onRemove,
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _QuantitySelector(
                      quantity: item.quantity,
                      maxQuantity: stock,
                      onChanged: onQuantityChanged,
                    ),
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
          onPressed: quantity <= 1 ? null : () => onChanged(quantity - 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text('$quantity', textAlign: TextAlign.center),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: quantity >= maxQuantity
              ? null
              : () => onChanged(quantity + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _CartSummarySection extends StatelessWidget {
  const _CartSummarySection({
    required this.summary,
    required this.discount,
    required this.total,
    required this.hasStockIssue,
    required this.hasSelection,
    required this.onVoucherTap,
    required this.onCheckout,
    required this.onRemoveVoucher,
    this.voucherCode,
  });

  final CartSummary summary;
  final double discount;
  final double total;
  final bool hasStockIssue;
  final bool hasSelection;
  final String? voucherCode;
  final VoidCallback onVoucherTap;
  final VoidCallback onCheckout;
  final VoidCallback onRemoveVoucher;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          _SummaryRow('Tổng số lượng', '${summary.itemCount} sản phẩm'),
          _SummaryRow('Tạm tính', summary.formattedSubtotal),
          TextButton.icon(
            onPressed: hasSelection ? onVoucherTap : null,
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('Áp mã giảm giá'),
          ),
          if (voucherCode != null)
            _SummaryRow(
              'Voucher $voucherCode',
              '-${formatCurrency(discount)}',
              trailing: IconButton(
                onPressed: onRemoveVoucher,
                icon: const Icon(Icons.close),
              ),
            ),
          _SummaryRow('Tổng cộng', formatCurrency(total), isEmphasis: true),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: hasStockIssue || !hasSelection ? null : onCheckout,
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.isEmphasis = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool isEmphasis;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = isEmphasis
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Giỏ hàng trống',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLoading extends StatefulWidget {
  const _CartLoading();

  @override
  State<_CartLoading> createState() => _CartLoadingState();
}

class _CartLoadingState extends State<_CartLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemBuilder: (_, _) => Container(
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _animation.value),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemCount: 4,
        );
      },
    );
  }
}

class _CartError extends StatelessWidget {
  const _CartError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
