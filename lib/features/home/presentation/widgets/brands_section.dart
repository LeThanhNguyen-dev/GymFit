import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_image.dart';
import '../../../products/providers/brand_providers.dart';
import '../../presentation/widgets/section_title.dart';
import 'categories_section.dart';

class BrandsSection extends ConsumerWidget {
  const BrandsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Thương hiệu'),
        SizedBox(
          height: 72,
          child: brandsAsync.when(
            loading: () => _BrandsShimmer(),
            error: (_, _) => const SizedBox.shrink(),
            data: (brands) {
              if (brands.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: brands.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final brand = brands[i];
                  return _BrandItem(
                    name: brand.name,
                    logoUrl: brand.logoUrl,
                    onTap: () => context.push(
                      '/products',
                      extra: {'brandId': brand.id},
                    ),
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

class _BrandItem extends StatelessWidget {
  const _BrandItem({
    required this.name,
    this.logoUrl,
    required this.onTap,
  });

  final String name;
  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: logoUrl != null
            ? AppImage(
                imageUrl: logoUrl,
                height: 36,
                fit: BoxFit.contain,
              )
            : Text(
                name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _BrandsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => ShimmerLoading(
        width: 100,
        height: 72,
        borderRadius: 12,
      ),
    );
  }
}
