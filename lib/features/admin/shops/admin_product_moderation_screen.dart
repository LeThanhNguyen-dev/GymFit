import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminProductModerationScreen extends ConsumerStatefulWidget {
  const AdminProductModerationScreen({super.key});
  @override
  ConsumerState<AdminProductModerationScreen> createState() => _AdminProductModerationScreenState();
}

class _AdminProductModerationScreenState extends ConsumerState<AdminProductModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt sản phẩm'), bottom: TabBar(
        controller: _tabCtrl,
        tabs: 'Chờ duyệt|Đã duyệt|Từ chối|Vi phạm'.split('|').map((t) => Tab(text: t)).toList(),
      )),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildList('pending'), _buildList('approved'), _buildList('rejected'), _buildViolations(),
      ]),
    );
  }

  Widget _buildList(String status) {
    final items = _mockProducts.where((p) => p['status'] == status).toList();
    if (items.isEmpty) return const Center(child: Text('Không có kết quả'));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => Card(
        child: ListTile(
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
          title: Text(items[i]['name'] as String, style: AppTextStyles.bodyMedium),
          subtitle: Text('${items[i]['shop']} - ${items[i]['date']}', style: AppTextStyles.labelSmall),
          trailing: status == 'pending'
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.cancel, color: AppColors.error), onPressed: () => _showRejectDialog(items[i])),
                ])
              : const Icon(Icons.chevron_right),
          onTap: () => _showProductDetail(items[i]),
        ),
      ),
    );
  }

  Widget _buildViolations() {
    final items = _mockProducts.where((p) => p['status'] == 'violation').toList();
    return items.isEmpty
        ? const Center(child: Text('Không có vi phạm'))
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
                title: Text(items[i]['name'] as String, style: AppTextStyles.bodyMedium),
                subtitle: Text('${items[i]['shop']} - ${items[i]['reason']}', style: AppTextStyles.labelSmall),
                trailing: PopupMenuButton(itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('Xem')),
                  const PopupMenuItem(value: 'remove', child: Text('Gỡ khỏi sàn')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Bỏ qua')),
                ]),
              ),
            ),
          );
  }

  void _showProductDetail(Map<String, dynamic> item) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 200, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: AppSpacing.md),
          Text(item['name'], style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Shop: ${item['shop']}', style: AppTextStyles.bodySmall),
          Text('Giá: 1.200.000₫', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text('Mô tả: Sản phẩm chất lượng cao phù hợp với người tập gym', style: AppTextStyles.bodySmall),
          const Spacer(),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Duyệt'), style: FilledButton.styleFrom(backgroundColor: AppColors.success))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(context); _showRejectDialog(item); }, child: const Text('Từ chối'))),
          ]),
        ]),
      ),
    ));
  }

  void _showRejectDialog(Map<String, dynamic> item) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Từ chối sản phẩm'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do từ chối...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Từ chối'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ));
  }

  static const _mockProducts = [
    {'name': 'Gym Bag Pro 2024', 'shop': 'SportLife', 'date': '15/06', 'status': 'pending', 'reason': ''},
    {'name': 'Đai tập tạ cao cấp', 'shop': 'Iron Gym', 'date': '14/06', 'status': 'pending', 'reason': ''},
    {'name': 'Bình lắc Whey', 'shop': 'Muscle Up', 'date': '13/06', 'status': 'pending', 'reason': ''},
    {'name': 'Quần áo tập Yoga', 'shop': 'Yoga Center', 'date': '10/06', 'status': 'approved', 'reason': ''},
    {'name': 'Protein Powder X', 'shop': 'SportLife', 'date': '08/06', 'status': 'violation', 'reason': 'Hàng nhái'},
    {'name': 'Thảm tập 10mm', 'shop': 'Yoga Center', 'date': '08/06', 'status': 'approved', 'reason': ''},
    {'name': 'Giày chạy bộ Pro', 'shop': 'Iron Gym', 'date': '05/06', 'status': 'rejected', 'reason': 'Thiếu giấy tờ'},
  ];
}
