import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

class VoucherStrip extends StatelessWidget {
  const VoucherStrip({super.key});

  static const _items = [
    _VoucherItem(icon: Icons.local_shipping, label: 'Freeship', color: Color(0xFF2ECC71), route: '/vouchers'),
    _VoucherItem(icon: Icons.discount, label: 'Voucher', color: Color(0xFFE74C3C), route: '/vouchers'),
    _VoucherItem(icon: Icons.qr_code, label: 'payOS', color: Color(0xFF3498DB), route: '/vouchers'),
    _VoucherItem(icon: Icons.whatshot, label: 'Deal hot', color: Color(0xFFE67E22), route: '/products'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _items.map((item) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push(item.route),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 6),
                    Text(item.label, style: AppTextStyles.labelSmall.copyWith(
                      color: item.color, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _VoucherItem {
  const _VoucherItem({required this.icon, required this.label, required this.color, required this.route});
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}
