import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import 'data/models/admin_user_model.dart';
import 'data/repositories/admin_user_repository.dart';
import 'providers/admin_user_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String? _roleFilter;
  String? _sellerStatusFilter;
  bool? _bannedFilter;
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _page = 1;

  AdminUsersFilter get _filter => AdminUsersFilter(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        role: _roleFilter,
        sellerStatus: _sellerStatusFilter,
        banned: _bannedFilter,
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          _buildSortRow(),
          Expanded(
            child: usersAsync.when(
              loading: () => const AppLoading(message: 'Đang tải người dùng...'),
              error: (error, _) => AppErrorWidget(
                message: 'Không thể tải danh sách người dùng: $error',
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
              data: (result) {
                final users = result.items;
                if (users.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    message: 'Không tìm thấy người dùng nào',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsersProvider);
                  },
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildUserTile(users[index]),
                  ),
                );
              },
            ),
          ),
          usersAsync.whenOrNull(data: (result) {
            final totalPages = (result.totalCount / _filter.pageSize).ceil();
            return PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalItems: result.totalCount,
              onPageChanged: (p) => setState(() => _page = p),
            );
          }) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Tìm kiếm người dùng...',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _roleFilter,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'storeowner', child: Text('Store Owner')),
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
              ],
              onChanged: (value) {
                setState(() {
                  _roleFilter = value;
                  _sellerStatusFilter = null;
                  _page = 1;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _sellerStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Seller',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) {
                setState(() {
                  _sellerStatusFilter = value;
                  _roleFilter = null;
                  _page = 1;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _bannedFilter == null
                  ? null
                  : _bannedFilter!
                      ? 'banned'
                      : 'not_banned',
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'not_banned', child: Text('Active')),
                DropdownMenuItem(value: 'banned', child: Text('Banned')),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'banned') {
                    _bannedFilter = true;
                  } else if (value == 'not_banned') {
                    _bannedFilter = false;
                  } else {
                    _bannedFilter = null;
                  }
                  _page = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Mới nhất'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('email', 'Email A-Z'),
      SortOption('email_desc', 'Email Z-A'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SortDropdown(
        value: currentKey,
        options: sortOptions,
        onChanged: (key) {
          setState(() {
            if (key.endsWith('_desc')) {
              _sortBy = key.replaceAll('_desc', '');
              _ascending = false;
            } else {
              _sortBy = key;
              _ascending = true;
            }
            _page = 1;
          });
        },
      ),
    );
  }

  Widget _buildUserTile(AdminUserModel user) {
    final banned = user.isBanned;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: banned
            ? Colors.red.shade100
            : Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          user.initials,
          style: TextStyle(
            color: banned
                ? Colors.red.shade700
                : Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.fullName ?? user.email,
        style: TextStyle(
          color: banned ? Colors.red : null,
          decoration: banned ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Row(
        children: [
          if (banned)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.block_flipped, size: 14, color: Colors.red),
              ),
          Expanded(
            child: Text(
              '${user.roleLabel}${user.sellerStatus != 'none' ? ' · ${user.sellerStatusLabel}' : ''}',
              style: TextStyle(color: banned ? Colors.red.shade300 : null),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.sellerStatus == 'pending')
            Icon(Icons.pending, color: Colors.orange.shade300, size: 20),
          const SizedBox(width: 4),
          if (banned)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
              tooltip: 'Unban',
              onPressed: () => _toggleBan(user, false),
            )
          else
            IconButton(
              icon: const Icon(Icons.block_flipped, color: Colors.grey),
              tooltip: 'Ban',
              onPressed: () => _toggleBan(user, true),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Details',
            onPressed: () => _showUserDetailDialog(user),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(AdminUserModel user, bool ban) async {
    final repo = ref.read(adminUserRepositoryProvider);
    final name = user.fullName ?? user.email;

    if (ban) {
      final reason = await AppDialog.input(
        context,
        title: 'Ban $name',
        initialValue: '',
      );
      if (reason == null || !context.mounted) return;
      final confirm = await AppDialog.confirm(
        context,
        title: 'Confirm ban',
        message: 'Ban $name${reason.isNotEmpty ? ': $reason' : ''}?',
        confirmText: 'Ban',
        confirmColor: Colors.red,
      );
      if (confirm != true || !context.mounted) return;
      try {
        await repo.toggleBan(user.id, banned: true, reason: reason.isNotEmpty ? reason : null);
        if (context.mounted) {
          showAppSnackbar(context, message: 'Đã cấm $name', type: SnackbarType.success);
          ref.invalidate(adminUsersProvider);
        }
      } catch (e) {
        if (context.mounted) showAppSnackbar(context, message: 'Lỗi: $e', type: SnackbarType.error);
      }
    } else {
      final confirm = await AppDialog.confirm(
        context,
        title: 'Unban',
        message: 'Bỏ cấm $name?',
        confirmText: 'Unban',
      );
      if (confirm != true || !context.mounted) return;
      try {
        await repo.toggleBan(user.id, banned: false);
        if (context.mounted) {
          showAppSnackbar(context, message: 'Đã bỏ cấm $name', type: SnackbarType.success);
          ref.invalidate(adminUsersProvider);
        }
      } catch (e) {
        if (context.mounted) showAppSnackbar(context, message: 'Lỗi: $e', type: SnackbarType.error);
      }
    }
  }

  Future<void> _showUserDetailDialog(AdminUserModel user) async {
    final repository = ref.read(adminUserRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.fullName ?? user.email,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Email', user.email),
                _detailRow('Vai trò', user.roleLabel),
                _detailRow('Trạng thái seller', user.sellerStatusLabel),
                _detailRow('Admin', user.isAdmin ? 'Yes' : 'No'),
                _detailRow('Bị cấm', user.isBanned ? 'Yes' : 'No'),
                if (user.isBanned && user.banReason != null)
                  _detailRow('Lý do cấm', user.banReason!),
                _detailRow('Đơn hàng', '${user.totalOrders}'),
                _detailRow('Đã chi', '${user.totalSpent.round()}d'),
                _detailRow('Đánh giá', '${user.reviewCount}'),
                if (user.lastLoginAt != null)
                  _detailRow(
                    'Đăng nhập cuối',
                    _formatDate(user.lastLoginAt!),
                  ),
                _detailRow('Ngày tạo', _formatDate(user.createdAt!)),
                const Divider(height: 24),
                const Text(
                  'Thao tác',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildRoleDropdown(user, setLocalState),
                const SizedBox(height: 8),
                _buildBanButton(user, repository, setLocalState),
                if (user.sellerStatus == 'pending') ...[
                  const SizedBox(height: 8),
                  _buildSellerApprovalButtons(user, repository, setLocalState),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
    if (mounted) ref.invalidate(adminUsersProvider);
  }

  Widget _buildRoleDropdown(
    AdminUserModel user,
    void Function(void Function()) setLocalState,
  ) {
    return DropdownButtonFormField<String>(
      value: user.role,
      decoration: const InputDecoration(
        labelText: 'Vai trò',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'customer', child: Text('Customer')),
        DropdownMenuItem(value: 'storeowner', child: Text('Store Owner')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (value) async {
        if (value == null || value == user.role) return;
        final confirm = await AppDialog.confirm(
          context,
          title: 'Đổi vai trò',
          message: 'Chuyển vai trò của ${user.fullName ?? user.email} thành $value?',
        );
        if (confirm != true || !context.mounted) return;
        try {
          await ref.read(adminUserRepositoryProvider).updateUserRole(
                user.id,
                value,
              );
          if (context.mounted) {
            showAppSnackbar(
              context,
              message: 'Đã cập nhật vai trò thành $value',
              type: SnackbarType.success,
            );
            setLocalState(() {});
          }
        } catch (e) {
          if (context.mounted) {
            showAppSnackbar(
              context,
              message: 'Lỗi: $e',
              type: SnackbarType.error,
            );
          }
        }
      },
    );
  }

  Widget _buildBanButton(
    AdminUserModel user,
    AdminUserRepository repository,
    void Function(void Function()) setLocalState,
  ) {
    if (user.isBanned) {
      return FilledButton.tonalIcon(
        onPressed: () async {
          final confirm = await AppDialog.confirm(
            context,
            title: 'Bỏ cấm',
            message:
                'Bỏ cấm ${user.fullName ?? user.email}?',
            confirmText: 'Bỏ cấm',
          );
          if (confirm != true || !context.mounted) return;
          try {
            await repository.toggleBan(user.id, banned: false);
            if (context.mounted) {
              showAppSnackbar(
                context,
                message: 'Đã bỏ cấm người dùng',
                type: SnackbarType.success,
              );
              setLocalState(() {});
            }
          } catch (e) {
            if (context.mounted) {
              showAppSnackbar(
                context,
                message: 'Lỗi: $e',
                type: SnackbarType.error,
              );
            }
          }
        },
        icon: const Icon(Icons.block_flipped),
        label: const Text('Bỏ cấm'),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: () async {
        final reason = await AppDialog.input(
          context,
          title: 'Cấm người dùng',
          initialValue: '',
        );
        if (reason == null || !context.mounted) return;
        final confirm = await AppDialog.confirm(
          context,
          title: 'Xác nhận cấm',
          message:
              'Cấm ${user.fullName ?? user.email}${reason.isNotEmpty ? ' với lý do: $reason' : ''}?',
          confirmText: 'Cấm',
          confirmColor: Colors.red,
        );
        if (confirm != true || !context.mounted) return;
        try {
          await repository.toggleBan(
            user.id,
            banned: true,
            reason: reason.isNotEmpty ? reason : null,
          );
          if (context.mounted) {
            showAppSnackbar(
              context,
              message: 'Đã cấm người dùng',
              type: SnackbarType.success,
            );
            setLocalState(() {});
          }
        } catch (e) {
          if (context.mounted) {
            showAppSnackbar(
              context,
              message: 'Lỗi: $e',
              type: SnackbarType.error,
            );
          }
        }
      },
      icon: const Icon(Icons.block_flipped),
      label: const Text('Cấm người dùng'),
    );
  }

  Widget _buildSellerApprovalButtons(
    AdminUserModel user,
    AdminUserRepository repository,
    void Function(void Function()) setLocalState,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              await _handleSellerApproval(user, 'approved');
              if (context.mounted) setLocalState(() {});
            },
            icon: const Icon(Icons.check),
            label: const Text('Duyệt'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _handleSellerApproval(user, 'rejected');
              if (context.mounted) setLocalState(() {});
            },
            icon: const Icon(Icons.close),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSellerApproval(AdminUserModel user, String status) async {
    final action = status == 'approved' ? 'duyệt' : 'từ chối';
    final confirm = await AppDialog.confirm(
      context,
      title: '${action == 'duyệt' ? 'Duyệt' : 'Từ chối'} seller',
      message:
          '${action == 'duyệt' ? 'Duyệt' : 'Từ chối'} yêu cầu bán hàng của ${user.fullName ?? user.email}?',
      confirmText: action == 'duyệt' ? 'Duyệt' : 'Từ chối',
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref
          .read(adminUserRepositoryProvider)
          .updateSellerStatus(user.id, status);
      if (context.mounted) {
        showAppSnackbar(
          context,
          message: 'Đã ${action} yêu cầu bán hàng',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar(
          context,
          message: 'Lỗi: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
