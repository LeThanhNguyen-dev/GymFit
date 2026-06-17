import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/menu_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class NavBar extends ConsumerStatefulWidget {
  final Function(String slug)? onCategorySelected;

  const NavBar({
    Key? key,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  late String? expandedLevel1;
  late String? expandedLevel2;

  @override
  void initState() {
    super.initState();
    expandedLevel1 = null;
    expandedLevel2 = null;
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(completeMenuProvider);

    return menuAsync.when(
      loading: () => _buildLoadingState(),
      error: (err, stack) {
        debugPrint('Navbar error: $err');
        return _buildErrorState(err.toString());
      },
      data: (menuItems) {
        if (menuItems.isEmpty) {
          return _buildEmptyState();
        }
        return _buildNavBar(context, menuItems);
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Lỗi tải menu',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Chưa có danh mục',
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, List<MenuItemModel> menuItems) {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            menuItems.length,
            (index) => _buildLevel1Item(
              context,
              menuItems[index],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevel1Item(
    BuildContext context,
    MenuItemModel level1,
  ) {
    final isExpanded = expandedLevel1 == level1.id;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value.startsWith('L2_')) {
          // Level 2 selected
          setState(() {
            expandedLevel1 = level1.id;
            expandedLevel2 = value.replaceFirst('L2_', '');
          });
        } else if (value.startsWith('L3_')) {
          // Level 3 selected
          widget.onCategorySelected?.call(value.replaceFirst('L3_', ''));
        } else {
          // Level 1 selected
          widget.onCategorySelected?.call(level1.slug);
        }
      },
      itemBuilder: (BuildContext context) {
        if (level1.children.isEmpty) {
          // No subcategories, just show the level 1 item
          return [];
        }

        return [
          // Section header for Level 2
          ...level1.children.asMap().entries.map((entry) {
            final level2Index = entry.key;
            final level2 = entry.value;
            final isLevel2Expanded = expandedLevel2 == level2.id;

            return PopupMenuItem<String>(
              value: 'L2_${level2.id}',
              onTap: () {
                setState(() {
                  expandedLevel2 = level2.id;
                });
              },
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    expandedLevel2 = level2.id;
                  });
                },
                child: Container(
                  constraints: BoxConstraints(minWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              level2.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (level2.children.isNotEmpty)
                            Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                        ],
                      ),
                      if (isLevel2Expanded && level2.children.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Container(
                            color: AppColors.background,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: level2.children
                                  .map((level3) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            widget.onCategorySelected
                                                ?.call(level3.slug);
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            level3.name,
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      if (level2Index <
                          level1.children.length -
                              1) // Divider between items
                        Divider(
                          color: AppColors.outlineVariant,
                          height: AppSpacing.md,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(
              level1.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isExpanded ? AppColors.primary : AppColors.onSurface,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (level1.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(
                  Icons.expand_more,
                  size: 18,
                  color: isExpanded ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Simplified hover-based navbar for desktop
class DesktopNavBar extends ConsumerStatefulWidget {
  final Function(String slug)? onCategorySelected;

  const DesktopNavBar({
    Key? key,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  ConsumerState<DesktopNavBar> createState() => _DesktopNavBarState();
}

class _DesktopNavBarState extends ConsumerState<DesktopNavBar> {
  String? hoveredLevel1;
  String? hoveredLevel2;

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(completeMenuProvider);

    return menuAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Lỗi tải menu: $err',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
        ),
      ),
      data: (menuItems) => Container(
        color: AppColors.surface,
        child: Row(
          children: List.generate(
            menuItems.length,
            (index) => MouseRegion(
              onEnter: (_) {
                setState(() {
                  hoveredLevel1 = menuItems[index].id;
                });
              },
              onExit: (_) {
                setState(() {
                  hoveredLevel1 = null;
                  hoveredLevel2 = null;
                });
              },
              child: _buildDesktopLevel1(menuItems[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLevel1(MenuItemModel level1) {
    final isHovered = hoveredLevel1 == level1.id;

    return Stack(
      children: [
        // Level 1 button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: InkWell(
            onTap: () {
              widget.onCategorySelected?.call(level1.slug);
            },
            child: Row(
              children: [
                Text(
                  level1.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isHovered ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (level1.children.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: isHovered
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Level 2 dropdown
        if (isHovered && level1.children.isNotEmpty)
          Positioned(
            top: 40,
            left: 0,
            child: Material(
              elevation: 8,
              child: Container(
                color: AppColors.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: level1.children
                      .map((level2) => MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                hoveredLevel2 = level2.id;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                hoveredLevel2 = null;
                              });
                            },
                            child: Container(
                              color: hoveredLevel2 == level2.id
                                  ? AppColors.background
                                  : AppColors.surface,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      widget.onCategorySelected
                                          ?.call(level2.slug);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.md),
                                      child: Text(
                                        level2.name,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Level 3 submenu
                                  if (level2.children.isNotEmpty &&
                                      hoveredLevel2 == level2.id)
                                    Container(
                                      color: AppColors.background,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: level2.children
                                            .map((level3) => InkWell(
                                                  onTap: () {
                                                    widget.onCategorySelected
                                                        ?.call(level3.slug);
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            AppSpacing.md),
                                                    child: Text(
                                                      level3.name,
                                                      style: AppTextStyles
                                                          .bodySmall,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
