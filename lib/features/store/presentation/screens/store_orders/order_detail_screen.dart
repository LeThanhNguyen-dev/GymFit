import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'order_list_screen.dart';

final storeOrderDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, id) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  // Fetch the order using RPC to bypass RLS, chaining .eq to get the specific order
  final orderResp = await supabase
      .rpc('get_store_orders', params: {'p_seller_id': userId})
      .eq('id', id)
      .maybeSingle();

  if (orderResp == null) return null;

  // Fetch order items using RPC
  final itemsResp = await supabase.rpc('get_store_order_items', params: {
    'p_order_id': id,
    'p_seller_id': userId,
  });

  final order = Map<String, dynamic>.from(orderResp);
  order['order_items'] = List<Map<String, dynamic>>.from(itemsResp);

  return order;
});

class StoreOrderDetailScreen extends ConsumerStatefulWidget {
  const StoreOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<StoreOrderDetailScreen> createState() => _StoreOrderDetailScreenState();
}

class _StoreOrderDetailScreenState extends ConsumerState<StoreOrderDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Chưa đăng nhập');

      await supabase.rpc('update_store_order_status', params: {
        'p_order_id': widget.orderId,
        'p_seller_id': userId,
        'p_status': status,
      });

      ref.invalidate(storeOrderDetailProvider(widget.orderId));
      ref.invalidate(storeOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái đơn thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(storeOrderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng'), elevation: 0),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng.'));
          }

          final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
          final status = order['status']?.toString() ?? 'pending';

          final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
          final shippingFee = double.tryParse(order['shipping_fee']?.toString() ?? '0') ?? 0.0;
          final discount = double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0.0;
          final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            children: [
              _section('Khách hàng', [
                _row('Tên', order['shipping_full_name']?.toString() ?? ''),
                _row('SĐT', order['shipping_phone']?.toString() ?? ''),
                _row('Địa chỉ', '${order['shipping_address1'] ?? ''}, ${order['shipping_city'] ?? ''}'),
              ]),
              const SizedBox(height: AppSpacing.md),
              _section('Sản phẩm', [
                ...items.map((item) {
                  final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
                  final formattedPrice = price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        image: item['image_url'] != null
                            ? DecorationImage(image: NetworkImage(item['image_url'].toString()), fit: BoxFit.cover)
                            : null,
                      ),
                      child: item['image_url'] == null ? const Icon(Icons.shopping_bag) : null,
                    ),
                    title: Text(item['product_name']?.toString() ?? '', style: AppTextStyles.bodySmall),
                    trailing: Text('$formattedPrice₫', style: AppTextStyles.labelMedium),
                    subtitle: Text('x${item['quantity']}', style: AppTextStyles.labelSmall),
                  );
                }),
              ]),
              const SizedBox(height: AppSpacing.md),
              _section('Trạng thái hiện tại', [
                _TimelineItem(title: 'Đã đặt hàng', time: '', active: true),
                _TimelineItem(title: 'Chờ xác nhận', time: '', active: true, isCurrent: status == 'pending'),
                _TimelineItem(title: 'Đang chuẩn bị', time: '', active: status != 'pending', isCurrent: status == 'confirmed' || status == 'processing'),
                _TimelineItem(title: 'Đang giao hàng', time: '', active: status == 'shipped' || status == 'delivered', isCurrent: status == 'shipped'),
                _TimelineItem(title: 'Hoàn thành', time: '', active: status == 'delivered', isCurrent: status == 'delivered'),
              ]),
              const SizedBox(height: AppSpacing.md),
              _section('Thanh toán', [
                _row('Tạm tính', '${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫'),
                _row('Phí ship', '${shippingFee.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫'),
                _row('Giảm giá', '-${discount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫'),
                const Divider(),
                _row('Tổng cộng', '${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫', bold: true),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isUpdating ? null : () => _updateStatus('confirmed'),
                        child: const Text('Xác nhận đơn'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUpdating ? null : () => _updateStatus('cancelled'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Từ chối'),
                      ),
                    ),
                  ],
                )
              else if (status == 'confirmed' || status == 'processing')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isUpdating ? null : () => _updateStatus('shipped'),
                    child: const Text('Giao cho đơn vị vận chuyển'),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: bold ? AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.bodyMedium),
        ],
      ),
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
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: isCurrent ? 16 : 12, height: isCurrent ? 16 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.primary : AppColors.surfaceContainerHighest,
                  border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: active ? FontWeight.w600 : null, color: active ? null : AppColors.onSurfaceVariant)),
              if (time.isNotEmpty) Text(time, style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
