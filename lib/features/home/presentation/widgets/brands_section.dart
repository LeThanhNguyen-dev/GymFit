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
          height: 130,
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
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: AppImage(
                          imageUrl: logoUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 32,
                            color: colorScheme.onSurfaceVariant),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            name.length > 8
                                ? '${name.substring(0, 7)}…'
                                : name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
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
        height: 130,
        borderRadius: 14,
      ),
    );
  }
}
