import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/menu_providers.dart';
import '../../../products/presentation/screens/category_landing_screen.dart';
import '../../presentation/widgets/section_title.dart';

class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(completeMenuProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Danh mục'),
        SizedBox(
          height: 90,
          child: treeAsync.when(
            loading: () => const _CategoriesShimmer(),
            error: (_, _) => const SizedBox.shrink(),
            data: (roots) {
              if (roots.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: roots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CategoryCard(
                  item: roots[i],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = categoryColors[item.colorIndex % categoryColors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryLandingScreen(item: item),
          ),
        );
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesShimmer extends StatelessWidget {
  const _CategoriesShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => const Column(
        children: [
          ShimmerLoading(width: 56, height: 56, borderRadius: 14),
          SizedBox(height: 4),
          ShimmerLoading(width: 44, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
