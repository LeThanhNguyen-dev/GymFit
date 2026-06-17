import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt Shop'), elevation: 0),
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Thông tin Shop|Cài đặt|Đánh giá'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildShopInfo(), _buildSettings(), _buildReviews(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Center(
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, shape: BoxShape.circle, border: Border.all(color: AppColors.outlineVariant)),
              child: const Icon(Icons.store, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            TextButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 16), label: const Text('Thay đổi avatar')),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(decoration: const InputDecoration(labelText: 'Tên shop', border: OutlineInputBorder()), controller: TextEditingController(text: 'GymFit Store')),
        const SizedBox(height: AppSpacing.md),
        TextField(decoration: const InputDecoration(labelText: 'Mô tả shop', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3),
        const SizedBox(height: AppSpacing.md),
        TextField(decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()), controller: TextEditingController(text: '0901 234 567')),
        const SizedBox(height: AppSpacing.md),
        TextField(decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()), controller: TextEditingController(text: '123 Nguyễn Huệ, Q.1, TP.HCM')),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: () {}, child: const Text('Lưu thông tin')),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Chính sách đổi trả', style: AppTextStyles.bodyMedium),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Giờ hoạt động', style: AppTextStyles.bodyMedium),
                subtitle: Text('T2-CN: 08:00 - 22:00', style: AppTextStyles.bodySmall),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: Text('Đơn hàng mới', style: AppTextStyles.bodyMedium),
                value: true, onChanged: (_) {},
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.inventory),
                title: Text('Cảnh báo hết hàng', style: AppTextStyles.bodyMedium),
                value: true, onChanged: (_) {},
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.rate_review),
                title: Text('Đánh giá mới', style: AppTextStyles.bodyMedium),
                value: false, onChanged: (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: Icon(Icons.pause_circle_outline, color: AppColors.error),
            title: Text('Tạm đóng shop', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            subtitle: Text('Shop sẽ không hiển thị với khách hàng', style: AppTextStyles.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Tạm đóng shop?'),
                content: const Text('Shop của bạn sẽ không hiển thị với khách hàng cho đến khi bạn mở lại.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    final reviews = List.generate(5, (i) => _mockReview(i));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(reviews[i]['user'], style: AppTextStyles.bodyMedium),
                const Spacer(),
                Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (s) => Icon(Icons.star, size: 16, color: s < int.parse(reviews[i]['rating']) ? AppColors.warning : AppColors.surfaceContainerHighest))),
              ]),
              const SizedBox(height: 8),
              Text(reviews[i]['product'], style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(reviews[i]['content'], style: AppTextStyles.bodySmall),
              if (reviews[i]['replied'] == false) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: () {}, child: const Text('Trả lời đánh giá')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _mockReview(int i) => {
    'user': 'Khách ${'ABCDE'[i]}',
    'product': 'Gym Bag Pro',
    'rating': '${i % 5 + 1}',
    'content': ['Sản phẩm tốt!', 'Giao hàng nhanh', 'Chất lượng ổn', 'Hơi nhỏ so với mô tả', 'Tuyệt vời!'][i],
    'replied': i % 2 == 0,
  };
}
