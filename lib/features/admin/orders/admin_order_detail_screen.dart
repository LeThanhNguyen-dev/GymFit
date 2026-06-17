import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Đơn $orderId'), actions: [
        PopupMenuButton(itemBuilder: (_) => [
          const PopupMenuItem(value: 'complete', child: Text('Force complete')),
          const PopupMenuItem(value: 'cancel', child: Text('Force cancel')),
          const PopupMenuItem(value: 'dispute', child: Text('Chuyển sang Dispute')),
        ], onSelected: (v) {
          if (v == 'complete') _showConfirm(context, 'Force complete', 'Xác nhận hoàn thành đơn thủ công?');
          else if (v == 'cancel') _showCancelDialog(context);
          else if (v == 'dispute') _showConfirm(context, 'Chuyển Dispute', 'Escalate đơn này thành khiếu nại?');
        }),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _buildSection('Thông tin đơn hàng', [
            _row('Order ID', orderId),
            _row('Ngày đặt', '15/06/2026 14:30'),
            _row('Tổng tiền', '1.200.000₫'),
            _row('Trạng thái', 'Chờ xác nhận'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('Thông tin người mua', [
            _row('Họ tên', 'Nguyễn Văn A'),
            _row('Email', 'nva@gmail.com'),
            _row('SĐT', '0901 234 567'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('Thông tin shop', [
            _row('Tên shop', 'SportLife'),
            _row('Chủ shop', 'Lê Văn C'),
            _row('SĐT', '0912 345 678'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('Sản phẩm', [
            _row('Gym Bag Pro x1', '1.200.000₫'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          ...rows,
        ]),
      ),
    );
  }

  Widget _buildTimeline() {
    final events = [
      ('Đặt hàng', '15/06 14:30', true),
      ('Thanh toán', '15/06 14:31', true),
      ('Xác nhận', '15/06 15:00', false),
      ('Đang giao', '', false),
      ('Hoàn thành', '', false),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Timeline', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          ...events.map((e) => _timelineItem(e.$1, e.$2, e.$3)),
        ]),
      ),
    );
  }

  Widget _timelineItem(String title, String time, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.primary : AppColors.surfaceContainerHighest),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontWeight: active ? FontWeight.w600 : null, color: active ? null : AppColors.onSurfaceVariant)),
        const Spacer(),
        if (time.isNotEmpty) Text(time, style: AppTextStyles.labelSmall),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium),
      ]),
    );
  }

  void _showConfirm(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận')),
      ],
    ));
  }

  void _showCancelDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Force cancel'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do huỷ...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận huỷ'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ));
  }
}
