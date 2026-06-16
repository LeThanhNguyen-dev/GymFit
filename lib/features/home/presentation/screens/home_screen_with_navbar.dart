import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/navbar.dart';

class HomeScreenWithNavBar extends StatefulWidget {
  const HomeScreenWithNavBar({Key? key}) : super(key: key);

  @override
  State<HomeScreenWithNavBar> createState() => _HomeScreenWithNavBarState();
}

class _HomeScreenWithNavBarState extends State<HomeScreenWithNavBar> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Column(
        children: [
          // Top AppBar
          AppBar(
            title: const Text('GymFit'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => context.push('/cart'),
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Navigation Bar
          if (isMobile)
            NavBar(
              onCategorySelected: (slug) {
                setState(() {
                  selectedCategory = slug;
                });
              },
            )
          else
            DesktopNavBar(
              onCategorySelected: (slug) {
                setState(() {
                  selectedCategory = slug;
                });
              },
            ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Category',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            selectedCategory ?? '',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = null;
                              });
                            },
                            child: const Text('Clear Selection'),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to GymFit',
                            style: AppTextStyles.headlineLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Select a category from the navigation bar above to browse products',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Featured products placeholder
                          Text(
                            'Featured Products',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 768
                                      ? 4
                                      : 2,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                            itemCount: 8,
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.sm),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Product ${index + 1}',
                                            style:
                                                AppTextStyles.bodySmall,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.xs),
                                          Text(
                                            '\$99.99',
                                            style: AppTextStyles
                                                .bodySmall
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
