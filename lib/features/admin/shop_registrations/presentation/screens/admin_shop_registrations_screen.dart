import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/enums/database_enums.dart';
import '../../../../register_shop/data/models/shop_registration_model.dart';
import '../../../../register_shop/providers/shop_registration_providers.dart';

class AdminShopRegistrationsScreen extends ConsumerStatefulWidget {
  const AdminShopRegistrationsScreen({super.key});

  @override
  ConsumerState<AdminShopRegistrationsScreen> createState() => _AdminShopRegistrationsScreenState();
}

class _AdminShopRegistrationsScreenState extends ConsumerState<AdminShopRegistrationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Shop'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Từ chối'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    final registrations = ref.watch(shopRegistrationsByStatusProvider(status));

    return registrations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store_mall_directory_outlined, size: 64, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('Không có đơn đăng ký', style: AppTextStyles.titleMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _RegistrationCard(
            registration: items[i],
            onTap: () => context.push(
              '${RouteNames.adminShopRegistrationsPath}/${items[i].id}',
            ),
          ),
        );
      },
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration, required this.onTap});

  final ShopRegistrationModel registration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (registration.status) {
      ShopRegistrationStatus.pending => AppColors.warning,
      ShopRegistrationStatus.approved => AppColors.success,
      ShopRegistrationStatus.rejected => AppColors.error,
    };

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(registration.shopName, style: AppTextStyles.titleMedium),
        subtitle: Text(
          '${registration.fullName} • ${registration.phoneNumber}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Chip(
          label: Text(registration.statusDisplay, style: AppTextStyles.labelSmall.copyWith(color: statusColor)),
          backgroundColor: statusColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
