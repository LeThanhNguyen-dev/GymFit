import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('User #${widget.userId}'), actions: [
        PopupMenuButton(itemBuilder: (_) => [
          const PopupMenuItem(value: 'ban', child: Text('Khoá tài khoản')),
          const PopupMenuItem(value: 'permanent_ban', child: Text('Khoá vĩnh viễn')),
          const PopupMenuItem(value: 'unban', child: Text('Mở khoá')),
          const PopupMenuItem(value: 'reset_pw', child: Text('Reset mật khẩu')),
          const PopupMenuItem(value: 'notify', child: Text('Gửi thông báo')),
        ], onSelected: _handleAction),
      ]),
      body: Column(children: [
        _buildInfo(),
        TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Đơn hàng'), Tab(text: 'Đánh giá'), Tab(text: 'Khiếu nại'),
        ]),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildOrders(), _buildReviews(), _buildComplaints(),
        ])),
      ]),
    );
  }

  Widget _buildInfo() {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, radius: 28, child: const Icon(Icons.person, size: 32, color: Colors.grey)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nguyễn Văn A', style: AppTextStyles.titleSmall),
            const SizedBox(height: 2),
            Text('nva@gmail.com', style: AppTextStyles.bodySmall),
            Text('0901 234 567 - Tham gia: 01/01/2026', style: AppTextStyles.labelSmall),
          ])),
          IconButton(icon: const Icon(Icons.store, color: AppColors.primary), onPressed: () {}, tooltip: 'Xem shop'),
        ]),
      ),
    );
  }

  Widget _buildOrders() {
    final orders = ['#DH2026001 - Gym Bag Pro - 1.200.000₫ - Hoàn thành', '#DH2026002 - Protein - 850.000₫ - Đã huỷ'];
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: orders.length, separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        title: Text(orders[i], style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildReviews() {
    return const Center(child: Text('Chưa có đánh giá'));
  }

  Widget _buildComplaints() {
    return const Center(child: Text('Chưa có khiếu nại'));
  }

  void _handleAction(String action) {
    if (action == 'ban') _showBanDialog();
    else if (action == 'permanent_ban') _showPermBanDialog();
    else if (action == 'unban') _showUnbanDialog();
    else if (action == 'reset_pw') _showResetPwDialog();
    else if (action == 'notify') _showNotifyDialog();
  }

  void _showBanDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Khoá tài khoản'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do khoá...')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('3 ngày'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('7 ngày'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('30 ngày'))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Khoá')),
      ],
    ));
  }

  void _showPermBanDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Khoá vĩnh viễn'),
      content: const Text('Bạn có chắc chắn muốn khoá vĩnh viễn tài khoản này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Khoá'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ));
  }

  void _showUnbanDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Mở khoá'),
      content: const Text('Mở khoá tài khoản này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận')),
      ],
    ));
  }

  void _showResetPwDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Reset mật khẩu'),
      content: const Text('Gửi email reset mật khẩu đến nva@gmail.com?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Gửi')),
      ],
    ));
  }

  void _showNotifyDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Gửi thông báo'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Tiêu đề...')),
        const SizedBox(height: 8),
        TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nội dung...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Gửi')),
      ],
    ));
  }
}
