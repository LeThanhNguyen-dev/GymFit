import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _filter = 'all';
  String _search = '';
  String _sort = 'date';

  @override
  Widget build(BuildContext context) {
    final users = _mockUsers.where((u) {
      if (_filter == 'active' && u['status'] != 'active') return false;
      if (_filter == 'banned' && u['status'] != 'banned') return false;
      if (_filter == 'unverified' && u['status'] != 'unverified') return false;
      if (_search.isNotEmpty && !u['name'].toString().toLowerCase().contains(_search.toLowerCase()) && !u['email'].toString().toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();

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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Row(children: [
            _filterChip('Tất cả', 'all'),
            _filterChip('Hoạt động', 'active'),
            _filterChip('Đã khoá', 'banned'),
            _filterChip('Chưa xác thực', 'unverified'),
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: users.isEmpty
            ? const Center(child: Text('Không tìm thấy user'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, child: Text((users[i]['name'] as String)[0], style: const TextStyle(color: Colors.grey))),
                    title: Text(users[i]['name'] as String, style: AppTextStyles.bodyMedium),
                    subtitle: Text('${users[i]['email']} - ${users[i]['orders']} đơn - ${users[i]['spent']}', style: AppTextStyles.labelSmall),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: users[i]['status'] == 'active' ? AppColors.success.withValues(alpha: 0.15) : users[i]['status'] == 'banned' ? AppColors.error.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text({
                        'active': 'Hoạt động', 'banned': 'Đã khoá', 'unverified': 'Chưa XT'
                      }[users[i]['status']] ?? '', style: AppTextStyles.labelSmall.copyWith(fontSize: 11, color: users[i]['status'] == 'active' ? AppColors.success : users[i]['status'] == 'banned' ? AppColors.error : AppColors.warning)),
                    ),
                    onTap: () => context.go('${RouteNames.adminUserDetailPath}/${users[i]['id']}'),
                  ),
                ),
              )),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label, style: AppTextStyles.labelSmall),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  static const _mockUsers = [
    {'id': '1', 'name': 'Nguyễn Văn A', 'email': 'nva@gmail.com', 'status': 'active', 'orders': 12, 'spent': '15.2M₫'},
    {'id': '2', 'name': 'Trần Thị B', 'email': 'ttb@gmail.com', 'status': 'active', 'orders': 8, 'spent': '8.5M₫'},
    {'id': '3', 'name': 'Lê Văn C', 'email': 'lvc@gmail.com', 'status': 'banned', 'orders': 3, 'spent': '1.2M₫'},
    {'id': '4', 'name': 'Phạm Thị D', 'email': 'ptd@gmail.com', 'status': 'unverified', 'orders': 0, 'spent': '0₫'},
    {'id': '5', 'name': 'Hoàng Văn E', 'email': 'hve@gmail.com', 'status': 'active', 'orders': 25, 'spent': '32.8M₫'},
  ];
}
