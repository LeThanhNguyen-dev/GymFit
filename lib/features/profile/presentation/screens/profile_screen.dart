import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/models/profile_model.dart';
import '../../providers/profile_providers.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildSimpleProfile(authState, context),
        data: (profile) => _buildFullProfile(context, ref, profile, authState),
      ),
    );
  }

  Widget _buildSimpleProfile(AuthStateData authState, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              (authState.user?.email ?? '?')[0].toUpperCase(),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authState.user?.email ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.editProfilePath),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Chỉnh sửa hồ sơ'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullProfile(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
    AuthStateData authState,
  ) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        const SizedBox(height: AppSpacing.lg),

        // Profile Header
        ProfileHeaderWidget(
          profile: profile,
          onEditTap: () => context.go(RouteNames.editProfilePath),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Menu items
        _MenuCard(
          title: 'Thông tin tài khoản',
          items: [
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Chỉnh sửa hồ sơ',
              onTap: () => context.go(RouteNames.editProfilePath),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ của tôi',
              onTap: () => context.go(RouteNames.addressListPath),
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Đơn hàng của tôi',
              onTap: () => context.go(RouteNames.orderHistoryPath),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Role info
        _MenuCard(
          title: 'Quyền hạn',
          items: [
            _MenuItem(
              icon: Icons.badge_outlined,
              label: 'Vai trò',
              trailing: Text(
                _roleDisplay(profile.role),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (profile.sellerStatus == 'pending')
              _MenuItem(
                icon: Icons.hourglass_bottom,
                label: 'Trạng thái bán hàng',
                trailing: Text(
                  'Đang chờ duyệt',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            if (profile.role == 'admin')
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Quản trị',
                onTap: () => context.go(RouteNames.adminDashboardPath),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Others
        _MenuCard(
          title: 'Khác',
          items: [
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'Hỗ trợ',
              onTap: () => context.go(RouteNames.supportListPath),
            ),
            _MenuItem(
              icon: Icons.star_outline,
              label: 'Đánh giá ứng dụng',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  String _roleDisplay(String role) {
    return switch (role) {
      'admin' => 'Quản trị viên',
      'staff' => 'Nhân viên',
      'storeowner' => 'Chủ cửa hàng',
      _ => 'Khách hàng',
    };
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: AppTextStyles.labelMedium),
          ),
          ...items.map((item) => _MenuRow(item: item)),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: AppColors.onSurfaceVariant),
      title: Text(item.label, style: AppTextStyles.bodyLarge),
      trailing: item.trailing ??
          Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      onTap: item.onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
