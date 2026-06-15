import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.count,
    this.child,
    this.color,
  });

  final int count;
  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && child == null) return const SizedBox.shrink();

    if (child != null) {
      return Badge(
        label: Text('$count'),
        backgroundColor: color,
        child: child,
      );
    }

    return Badge(
      label: Text('$count'),
      backgroundColor: color,
      isLabelVisible: count > 0,
    );
  }
}
