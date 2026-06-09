import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum SnackbarType { success, error, info }

void showAppSnackbar(
  BuildContext context, {
  required String message,
  SnackbarType type = SnackbarType.info,
}) {
  final color = switch (type) {
    SnackbarType.success => AppColors.primary,
    SnackbarType.error => AppColors.error,
    SnackbarType.info => AppColors.onSurfaceVariant,
  };

  final icon = switch (type) {
    SnackbarType.success => Icons.check_circle_outline,
    SnackbarType.error => Icons.error_outline,
    SnackbarType.info => Icons.info_outline,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
}
