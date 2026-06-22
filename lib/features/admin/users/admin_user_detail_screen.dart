import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'data/models/admin_user_model.dart';
import 'providers/admin_user_providers.dart';
import '../../orders/providers/order_providers.dart';
import '../../orders/data/models/order_model.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(adminUserDetailProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: Text('User #${widget.userId.substring(0, math.min(8, widget.userId.length))}'), actions: [
        userAsync.when(
          data: (user) => PopupMenuButton(
            itemBuilder: (_) => [
              if (!user.isBanned) ...[
                const PopupMenuItem(value: 'ban', child: Text('Khoá tài khoản')),
              ] else ...[
                const PopupMenuItem(value: 'unban', child: Text('Mở khoá')),
              ],
              const PopupMenuItem(value: 'reset_pw', child: Text('Reset mật khẩu')),
            ],
            onSelected: (v) => _handleAction(v, user),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ]),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (user) => Column(children: [
          _buildInfo(user),
          TabBar(controller: _tabCtrl, tabs: const [
            Tab(text: 'Đơn hàng'), Tab(text: 'Đánh giá'), Tab(text: 'Khiếu nại'),
          ]),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _buildOrders(), _buildReviews(), _buildComplaints(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildInfo(AdminUserModel user) {
    final dateStr = user.createdAt != null
        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
        : 'Chưa rõ';

    return Card(
      margin: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainerHighest,
            radius: 28,
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.fullName ?? 'Chưa đặt tên', style: AppTextStyles.titleSmall),
            const SizedBox(height: 2),
            Text(user.email, style: AppTextStyles.bodySmall),
            Text('${user.phone ?? "Chưa cài SĐT"} - Tham gia: $dateStr', style: AppTextStyles.labelSmall),
            const SizedBox(height: 4),
            Text('Vai trò: ${user.roleLabel} • Trạng thái: ${user.isBanned ? "Đã khóa" : "Hoạt động"}', style: AppTextStyles.labelSmall.copyWith(color: user.isBanned ? AppColors.error : AppColors.success)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildOrders() {
    return FutureBuilder<List<OrderModel>>(
      future: ref.read(orderRepositoryProvider).getOrders(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final order = orders[i];
            final price = order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
            return ListTile(
              title: Text('Đơn #${order.orderNumber}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('${order.statusText} • $price₫', style: AppTextStyles.bodySmall),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.go('${RouteNames.adminOrderDetailPath}/${order.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildReviews() {
    return const Center(child: Text('Chưa có đánh giá'));
  }

  Widget _buildComplaints() {
    return const Center(child: Text('Chưa có khiếu nại'));
  }

  void _handleAction(String action, AdminUserModel user) {
    if (action == 'ban') _showBanDialog(user);
    else if (action == 'unban') _showUnbanDialog(user);
    else if (action == 'reset_pw') _showResetPwDialog(user);
  }

  void _showBanDialog(AdminUserModel user) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Khoá tài khoản'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do khoá...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(adminUserRepositoryProvider).toggleBan(
              user.id,
              banned: true,
              reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            );
            if (!mounted) return;
            Navigator.pop(context);
            ref.invalidate(adminUserDetailProvider(widget.userId));
            ref.invalidate(adminUsersProvider);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã khoá tài khoản')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          }
        }, child: const Text('Khoá')),
      ],
    ));
  }

  void _showUnbanDialog(AdminUserModel user) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Mở khoá'),
      content: const Text('Mở khoá tài khoản này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(adminUserRepositoryProvider).toggleBan(user.id, banned: false);
            if (!mounted) return;
            Navigator.pop(context);
            ref.invalidate(adminUserDetailProvider(widget.userId));
            ref.invalidate(adminUsersProvider);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mở khoá tài khoản')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          }
        }, child: const Text('Xác nhận')),
      ],
    ));
  }

  void _showResetPwDialog(AdminUserModel user) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Reset mật khẩu'),
      content: Text('Gửi email reset mật khẩu đến ${user.email}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi yêu cầu reset mật khẩu đến ${user.email}')));
        }, child: const Text('Gửi')),
      ],
    ));
  }
}
