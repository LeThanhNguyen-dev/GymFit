import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({super.key});

  static const _items = [
    _ShortcutItem(icon: Icons.category, label: 'Danh mục', route: '/products'),
    _ShortcutItem(icon: Icons.local_offer, label: 'Voucher', route: '/vouchers'),
    _ShortcutItem(icon: Icons.trending_up, label: 'Bán chạy', route: '/products'),
    _ShortcutItem(icon: Icons.fiber_new, label: 'Hàng mới', route: '/products'),
    _ShortcutItem(icon: Icons.store, label: 'Shop', route: '/shop-products'),
    _ShortcutItem(icon: Icons.receipt_long, label: 'Đơn hàng', route: '/orders'),
    _ShortcutItem(icon: Icons.favorite, label: 'Yêu thích', route: '/wishlist'),
    _ShortcutItem(icon: Icons.headset_mic, label: 'Hỗ trợ', route: '/support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 0,
          childAspectRatio: 1.15,
        ),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => context.push(item.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Spacer(flex: 1),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(height: 3),
                Text(item.label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                const Spacer(flex: 2),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}
