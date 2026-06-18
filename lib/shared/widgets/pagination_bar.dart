import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  List<int> _visiblePages() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int>{};
    pages.add(1);
    pages.add(totalPages);
    for (var i = page - 2; i <= page + 2; i++) {
      if (i >= 1 && i <= totalPages) {
        pages.add(i);
      }
    }
    final sorted = pages.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && totalItems <= 20) return const SizedBox.shrink();

    final visible = _visiblePages();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            '$totalItems items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          const SizedBox(width: 4),
          ...List.generate(visible.length, (i) {
            final p = visible[i];
            final showEllipsis = i > 0 && p - visible[i - 1] > 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showEllipsis)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                _PageButton(
                  page: p,
                  isCurrent: p == page,
                  onTap: () => onPageChanged(p),
                ),
              ],
            );
          }),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed:
                page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  final int page;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : null,
            color: isCurrent
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}
