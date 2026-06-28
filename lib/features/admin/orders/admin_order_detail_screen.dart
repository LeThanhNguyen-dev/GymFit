import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../orders/providers/order_providers.dart';
import '../../orders/data/models/order_model.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final historyAsync = ref.watch(orderStatusHistoryProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${orderId.substring(0, math.min(8, orderId.length))}'),
        actions: [
          orderAsync.when(
            data: (order) => order == null
                ? const SizedBox.shrink()
                : PopupMenuButton<OrderStatus>(
                    itemBuilder: (_) => OrderStatus.values
                        .map((status) => PopupMenuItem(
                              value: status,
                              child: Text('Chuyển sang: ${status.name}'),
                            ))
                        .toList(),
                    onSelected: (status) => _updateStatus(context, ref, status),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          final price = order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
          final dateStr = order.createdAt != null
              ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year} ${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
              : 'Chưa rõ';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            children: [
              _buildSection('Thông tin đơn hàng', [
                _row('Mã đơn hàng', order.orderNumber),
                _row('Ngày đặt', dateStr),
                _row('Tổng tiền', '$price₫'),
                _row('Trạng thái', order.statusText),
              ]),
              const SizedBox(height: AppSpacing.md),
              _buildSection('Thông tin giao hàng', [
                _row('Họ tên người nhận', order.shippingFullName),
                _row('Số điện thoại', order.shippingPhone),
                _row('Địa chỉ', '${order.shippingAddress1}, ${order.shippingCity}'),
                if (order.customerNote != null && order.customerNote!.isNotEmpty)
                  _row('Ghi chú của khách', order.customerNote!),
              ]),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                'Sản phẩm (${order.items.length})',
                order.items.map((item) {
                  final itemPrice = item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text('$itemPrice₫', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTimelineSection(historyAsync),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(AsyncValue<List<OrderStatusHistoryModel>> historyAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lịch sử trạng thái', style: AppTextStyles.titleSmall),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Không thể tải lịch sử: $err', style: AppTextStyles.bodySmall),
              data: (history) {
                if (history.isEmpty) {
                  return Text('Chưa có lịch sử thay đổi trạng thái.', style: AppTextStyles.bodySmall);
                }
                return Column(
                  children: history.map<Widget>((h) {
                    final time = h.createdAt != null
                        ? '${h.createdAt!.day}/${h.createdAt!.month} ${h.createdAt!.hour.toString().padLeft(2, '0')}:${h.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chuyển sang: ${h.toStatus.name}',
                                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (h.note != null && h.note!.isNotEmpty)
                                  Text(h.note!, style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(time, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, OrderStatus newStatus) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn muốn chuyển trạng thái đơn hàng sang "${newStatus.name}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Lý do',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null) throw Exception('Vui lòng đăng nhập lại');

      await ref.read(orderRepositoryProvider).updateOrderStatus(
        orderId,
        newStatus,
        userId,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );

      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(orderStatusHistoryProvider(orderId));
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }
}
