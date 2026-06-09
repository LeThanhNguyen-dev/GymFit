import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
  })  : _variant = _AppButtonVariant.primary,
        _loading = loading;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
  })  : _variant = _AppButtonVariant.secondary,
        _loading = loading;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
  })  : _variant = _AppButtonVariant.outline,
        _loading = loading;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
  })  : _variant = _AppButtonVariant.text,
        _loading = loading;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final Widget? icon;
  final bool _loading;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final child = _loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    final style = switch (_variant) {
      _AppButtonVariant.primary => FilledButton.styleFrom(
          minimumSize: expanded ? const Size(double.infinity, 56) : const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      _AppButtonVariant.secondary => FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.secondary,
          minimumSize: expanded ? const Size(double.infinity, 56) : const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      _AppButtonVariant.outline => OutlinedButton.styleFrom(
          minimumSize: expanded ? const Size(double.infinity, 56) : const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      _AppButtonVariant.text => TextButton.styleFrom(
          minimumSize: expanded ? const Size(double.infinity, 56) : const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
    };

    return switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: child,
        ),
      _AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: loading ? null : onPressed,
          style: style,
          child: child,
        ),
      _AppButtonVariant.outline => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: child,
        ),
      _AppButtonVariant.text => TextButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: child,
        ),
    };
  }
}

enum _AppButtonVariant { primary, secondary, outline, text }
