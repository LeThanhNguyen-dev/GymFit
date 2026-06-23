import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'data/models/admin_user_model.dart';
import 'providers/admin_user_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _filter = 'all';
  String _search = '';
  String _sort = 'date';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filter = AdminUsersFilter(
      search: _search.trim().isEmpty ? null : _search.trim(),
      role: _roleFilter == 'all' ? null : _roleFilter,
      sellerStatus: _filter == 'unverified' ? 'pending' : null,
      banned: _filter == 'active' ? false : (_filter == 'banned' ? true : null),
      sortBy: _sort == 'date' ? 'created_at' : (_sort == 'orders' ? 'total_orders' : 'total_spent'),
      ascending: false,
      page: 1,
      pageSize: 100,
    );

    final usersAsync = ref.watch(adminUsersProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý User'), actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(value: 'date', checked: _sort == 'date', child: const Text('Ngày tạo')),
            CheckedPopupMenuItem(value: 'orders', checked: _sort == 'orders', child: const Text('Số đơn')),
            CheckedPopupMenuItem(value: 'spent', checked: _sort == 'spent', child: const Text('Tổng chi tiêu')),
          ],
        ),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm user...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _filter,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'banned', child: Text('Đã khoá')),
                    DropdownMenuItem(value: 'unverified', child: Text('Chờ duyệt Shop')),
                  ],
                  onChanged: (v) => setState(() => _filter = v ?? 'all'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _roleFilter,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả vai trò')),
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'storeowner', child: Text('Store Owner')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
            data: (result) {
              final users = result.items;
              if (users.isEmpty) {
                return const Center(child: Text('Không tìm thấy user'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminUsersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _buildUserCard(users[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showEditDialog(AdminUserModel user) {
    String role = user.role;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('Edit user role'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('User: ${user.email}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Vai trò'),
            items: const [
              DropdownMenuItem(value: 'customer', child: Text('Customer')),
              DropdownMenuItem(value: 'storeowner', child: Text('Store Owner')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => setLocalState(() => role = v ?? role),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            try {
              await ref.read(adminUserRepositoryProvider).updateUserRole(user.id, role);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ref.invalidate(adminUsersProvider);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật vai trò thành công!')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
            }
          }, child: const Text('Save')),
        ],
      ),
    ));
  }

  void _toggleBan(AdminUserModel user, bool ban) {
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(ban ? 'Ban user' : 'Restore user'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ban ? 'Ban "${user.fullName ?? user.email}"?' : 'Restore "${user.fullName ?? user.email}"?'),
          if (ban) ...[
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Lý do ban', border: OutlineInputBorder())),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(adminUserRepositoryProvider).toggleBan(
              user.id,
              banned: ban,
              reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
            );
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ref.invalidate(adminUsersProvider);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ban ? 'Đã khoá tài khoản!' : 'Đã mở khoá tài khoản!')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          }
        }, child: Text(ban ? 'Ban' : 'Restore')),
      ],
    ));
  }

  Widget _buildUserCard(AdminUserModel user) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final statusColors = {
      'active': AppColors.success,
      'banned': AppColors.error,
      'unverified': AppColors.warning
    };
    final statusLabels = {
      'active': 'Hoạt động',
      'banned': 'Đã khoá',
      'unverified': 'Chờ duyệt'
    };

    final status = user.isBanned ? 'banned' : (user.sellerStatus == 'pending' ? 'unverified' : 'active');

    Widget statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (statusColors[status] ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusLabels[status] ?? '',
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 11,
          color: statusColors[status] ?? Colors.grey,
        ),
      ),
    );

    final displaySpent = user.totalSpent.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    if (!isMobile) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceContainerHighest,
            child: Text(
              user.initials,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          title: Text(user.fullName ?? 'Chưa cập nhật', style: AppTextStyles.bodyMedium),
          subtitle: Text(
            '${user.email} - ${user.totalOrders} đơn - $displaySpent₫ • ${user.roleLabel}',
            style: AppTextStyles.labelSmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              statusBadge,
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showEditDialog(user),
              ),
              IconButton(
                icon: Icon(
                  !user.isBanned ? Icons.block : Icons.restore,
                  size: 18,
                  color: !user.isBanned ? AppColors.error : AppColors.success,
                ),
                onPressed: () => _toggleBan(user, !user.isBanned),
              ),
            ],
          ),
          onTap: () => context.go(
            RouteNames.adminUserDetailPath.replaceAll(':id', user.id),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: () => context.go(
          RouteNames.adminUserDetailPath.replaceAll(':id', user.id),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceContainerHighest,
                    child: Text(
                      user.initials,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName ?? 'Chưa cập nhật',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  statusBadge,
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${user.totalOrders} đơn', style: AppTextStyles.labelSmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$displaySpent₫', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditDialog(user),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          !user.isBanned ? Icons.block_flipped : Icons.restore,
                          size: 20,
                          color: !user.isBanned ? AppColors.error : AppColors.success,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _toggleBan(user, !user.isBanned),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
