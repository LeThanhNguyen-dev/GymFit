import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/theme/app_text_styles.dart';

class PriceText extends StatelessWidget {
  const PriceText(
    this.price, {
    super.key,
    this.style,
    this.showZero = false,
  });

  final num price;
  final TextStyle? style;
  final bool showZero;

  @override
  Widget build(BuildContext context) {
    if (!showZero && price <= 0) return const SizedBox.shrink();

    return Text(
      formatCurrency(price),
      style: style ?? AppTextStyles.titleMedium,
    );
  }
}
