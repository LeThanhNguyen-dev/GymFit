import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.primary,
    this.showValue = false,
  });

  final double rating;
  final double size;
  final Color color;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (_, _) => Icon(Icons.star, color: color, size: size),
          itemCount: 5,
          itemSize: size,
          direction: Axis.horizontal,
        ),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 36,
  });

  final double rating;
  final ValueChanged<double>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: size,
      itemBuilder: (_, index) {
        return Icon(
          Icons.star,
          color: AppColors.primary,
          size: size,
        );
      },
      onRatingUpdate: onChanged ?? (_) {},
    );
  }
}
