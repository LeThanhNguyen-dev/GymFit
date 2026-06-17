import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class StoreOrderDetailScreen extends ConsumerWidget {
  const StoreOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Đơn $orderId'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _section('Khách hàng', [
            _row('Tên', 'Nguyễn Văn A'),
            _row('SĐT', '0901 234 567'),
            _row('Địa chỉ', '123 Nguyễn Huệ, Quận 1, TP.HCM'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _section('Sản phẩm', [
            ...List.generate(2, (i) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))),
              title: Text('Gym Bag Pro - Đen / M', style: AppTextStyles.bodySmall),
              trailing: Text('${i == 0 ? "1.200.000₫" : "180.000₫"}', style: AppTextStyles.labelMedium),
              subtitle: Text('x${i + 1}', style: AppTextStyles.labelSmall),
            )),
          ]),
          const SizedBox(height: AppSpacing.md),
          _section('Trạng thái', [
            _TimelineItem(title: 'Đã đặt hàng', time: '14:30 15/06', active: true),
            _TimelineItem(title: 'Chờ xác nhận', time: '14:30 15/06', active: true, isCurrent: true),
            _TimelineItem(title: 'Đang chuẩn bị', time: '', active: false),
            _TimelineItem(title: 'Đang giao hàng', time: '', active: false),
            _TimelineItem(title: 'Hoàn thành', time: '', active: false),
          ]),
          const SizedBox(height: AppSpacing.md),
          _section('Thanh toán', [
            _row('Tạm tính', '1.380.000₫'),
            _row('Phí ship', '30.000₫'),
            _row('Giảm giá', '-100.000₫'),
            const Divider(),
            _row('Tổng cộng', '1.310.000₫', bold: true),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () {}, child: const Text('Xác nhận đơn'))),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Từ chối'))),
          ]),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: bold ? AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.bodyMedium),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.title, required this.time, required this.active, this.isCurrent = false});
  final String title, time;
  final bool active, isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Column(children: [
          Container(
            width: isCurrent ? 16 : 12, height: isCurrent ? 16 : 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.primary : AppColors.surfaceContainerHighest, border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null),
          ),
        ]),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: active ? FontWeight.w600 : null, color: active ? null : AppColors.onSurfaceVariant)),
          if (time.isNotEmpty) Text(time, style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}
