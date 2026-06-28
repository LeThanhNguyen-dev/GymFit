import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/providers/product_providers.dart';

class FlashSaleSection extends ConsumerWidget {
  const FlashSaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashAsync = ref.watch(flashSaleProductsProvider);
    return flashAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFE74C3C), size: 22),
                  const SizedBox(width: 6),
                  Text('Flash Sale', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFE74C3C))),
                  const SizedBox(width: 12),
                  _CountdownTimer(),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/products'),
                    child: Text('Xem tất cả', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _FlashProductCard(product: products[i]),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Duration _remaining = const Duration(hours: 11, minutes: 59, seconds: 59);

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      children: [
        _timeBox(h.substring(0, 1)), _timeBox(h.substring(1, 2)),
        const Text(':', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        _timeBox(m.substring(0, 1)), _timeBox(m.substring(1, 2)),
        const Text(':', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        _timeBox(s.substring(0, 1)), _timeBox(s.substring(1, 2)),
      ],
    );
  }

  Widget _timeBox(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

class _FlashProductCard extends StatelessWidget {
  const _FlashProductCard({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final discount = product.compareAtPrice != null && product.compareAtPrice! > product.basePrice
        ? ((product.compareAtPrice! - product.basePrice) / product.compareAtPrice! * 100).round()
        : 0;
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    height: 120, width: double.infinity,
                    color: AppColors.surfaceContainerHighest,
                    child: product.images.isNotEmpty && product.images.first.url.isNotEmpty
                        ? Image.network(product.images.first.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                        : const Icon(Icons.image),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    left: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                      ),
                      child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(formatCurrency(product.basePrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C))),
                  if (product.compareAtPrice != null)
                    Text(formatCurrency(product.compareAtPrice!), style: const TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
