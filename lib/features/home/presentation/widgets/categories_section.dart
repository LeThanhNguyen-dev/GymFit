import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_image.dart';
import '../../../products/providers/category_providers.dart';
import '../../presentation/widgets/section_title.dart';

class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Danh mục'),
        SizedBox(
          height: 100,
          child: categoriesAsync.when(
            loading: () => _CategoriesShimmer(),
            error: (_, _) => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final category = categories[i];
                  return _CategoryItem(
                    name: category.name,
                    imageUrl: category.imageUrl ?? category.iconUrl,
                    onTap: () => context.push('/products', extra: {
                      'categoryId': category.id,
                    }),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.name,
    this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? AppImage(imageUrl: imageUrl, fit: BoxFit.cover)
                : Icon(
                    Icons.fitness_center_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (_, _) => const Column(
        children: [
          ShimmerLoading(width: 64, height: 64, borderRadius: 16),
          SizedBox(height: 6),
          ShimmerLoading(width: 50, height: 10, borderRadius: 4),
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
