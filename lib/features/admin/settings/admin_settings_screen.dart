import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 5, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt Hệ thống'), bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Danh mục'),
          Tab(text: 'Banner'),
          Tab(text: 'Thông báo'),
          Tab(text: 'Cấu hình'),
          Tab(text: 'Admin Accounts'),
        ],
      )),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildCategories(),
        _buildBanners(),
        _buildNotifications(),
        _buildConfig(),
        _buildAdminAccounts(),
      ]),
    );
  }

  Widget _buildCategories() {
    final cats = [
      ('Thể thao', '🏋️', [('Dụng cụ tập gym', null), ('Quần áo thể thao', null)]),
      ('Dinh dưỡng', '🥤', [('Whey Protein', null), ('Vitamin & TPBVSK', null)]),
      ('Phụ kiện', '🎒', [('Balo & Túi', null), ('Bình nước', null)]),
      ('Yoga & Thư giãn', '🧘', [('Thảm tập', null), ('Đạo cụ yoga', null)]),
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Row(children: [
          Expanded(child: Text('Danh mục sản phẩm', style: AppTextStyles.titleSmall)),
          FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.add, size: 18), label: const Text('Thêm')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        ...cats.map((c) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${c.$1} ${c.$2}', style: AppTextStyles.bodyMedium),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, size: 16, color: AppColors.error), onPressed: () {}),
                const Icon(Icons.drag_handle),
              ]),
              ...c.$3.map((sub) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: ListTile(
                  title: Text(sub.$1, style: AppTextStyles.bodySmall),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, size: 14), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete, size: 14, color: AppColors.error), onPressed: () {}),
                  ]),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              )),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Thêm danh mục con')),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _buildBanners() {
    final banners = [
      {'name': 'Summer Sale', 'active': true, 'order': 1},
      {'name': 'New Arrivals', 'active': true, 'order': 2},
      {'name': 'GymFit Exclusive', 'active': false, 'order': 3},
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Row(children: [
          Expanded(child: Text('Banner đang hiển thị', style: AppTextStyles.titleSmall)),
          FilledButton.tonalIcon(onPressed: () => _showAddBannerDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Thêm')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        ...banners.map((b) => Card(
          child: ListTile(
            leading: Container(width: 64, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
            title: Text(b['name'] as String, style: AppTextStyles.bodyMedium),
            subtitle: Text('Thứ tự: ${b['order']}', style: AppTextStyles.labelSmall),
            trailing: Switch(value: b['active'] as bool, onChanged: (_) {}),
          ),
        )),
      ],
    );
  }

  Widget _buildNotifications() {
    final targetCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('Gửi thông báo', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField(
          items: ['Tất cả user', 'Tất cả shop', 'User cụ thể', 'Shop cụ thể'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (_) {},
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Đối tượng'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(controller: targetCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ID User / Shop (nếu chọn cụ thể)')),
        const SizedBox(height: AppSpacing.sm),
        TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Tiêu đề')),
        const SizedBox(height: AppSpacing.sm),
        TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Nội dung')),
        const SizedBox(height: AppSpacing.sm),
        TextField(decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Deep link (tuỳ chọn)')),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: () {}, child: const Text('Gửi thông báo')),
      ],
    );
  }

  Widget _buildConfig() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('Cấu hình hệ thống', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _configItem('Tự động hoàn thành đơn sau (ngày)', '7'),
        _configItem('Giải phóng tiền cho shop sau (ngày)', '3'),
        _configItem('Thời gian khiếu nại sau nhận hàng (ngày)', '14'),
        _configItem('Số lần đăng ký shop tối đa', '3'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: () {}, child: const Text('Lưu cấu hình')),
      ],
    );
  }

  Widget _buildAdminAccounts() {
    final admins = [
      {'name': 'Admin Master', 'email': 'admin@gymfit.com', 'role': 'super'},
      {'name': 'Moderator 1', 'email': 'mod1@gymfit.com', 'role': 'mod'},
      {'name': 'Support Agent', 'email': 'support@gymfit.com', 'role': 'support'},
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Row(children: [
          Expanded(child: Text('Tài khoản Admin', style: AppTextStyles.titleSmall)),
          FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.person_add, size: 18), label: const Text('Thêm admin')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        ...admins.map((a) => Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, child: Icon(Icons.admin_panel_settings, color: a['role'] == 'super' ? AppColors.warning : Colors.grey, size: 20)),
            title: Text(a['name'] as String, style: AppTextStyles.bodyMedium),
            subtitle: Text('${a['email']} - ${a['role']}', style: AppTextStyles.labelSmall),
            trailing: PopupMenuButton(itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
              const PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: AppColors.error))),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _configItem(String label, String defaultValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        SizedBox(
          width: 80,
          child: TextField(
            controller: TextEditingController(text: defaultValue),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
          ),
        ),
      ]),
    );
  }

  void _showAddBannerDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Thêm Banner'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 120, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey))),
        const SizedBox(height: 8),
        TextField(decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Link đích')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Thứ tự'), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextField(decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Thời gian (ngày)'), keyboardType: TextInputType.number)),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Thêm')),
      ],
    ));
  }
}
