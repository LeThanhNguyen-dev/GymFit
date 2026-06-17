import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class StoreOrderListScreen extends ConsumerStatefulWidget {
  const StoreOrderListScreen({super.key});
  @override
  ConsumerState<StoreOrderListScreen> createState() => _StoreOrderListScreenState();
}

class _StoreOrderListScreenState extends ConsumerState<StoreOrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 6, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.sm, AppSpacing.pageHorizontal, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn hoặc tên khách...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Chờ xác nhận|Đang chuẩn bị|Đang giao|Hoàn thành|Đã huỷ|Trả hàng'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: List.generate(6, (_) => _buildOrderList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final orders = List.generate(8, (i) => _mockOrder(i));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _OrderCard(
        order: orders[i],
        onTap: () => context.push('${RouteNames.storeOrdersPath}/${orders[i]['id']}'),
      ),
    );
  }

  Map<String, dynamic> _mockOrder(int i) => {
    'id': 'DH${20260000 + i}',
    'customer': 'Nguyễn Văn ${'ABCDEFGH'[i]}',
    'total': '${(150 + i * 50)}.000₫',
    'items': i % 3 + 1,
    'time': '${10 + i}:${i * 7} ${i < 4 ? "hôm nay" : "hôm qua"}',
    'status': ['Chờ xác nhận', 'Đang chuẩn bị', 'Đang giao', 'Hoàn thành', 'Đã huỷ', 'Trả hàng'][i % 6],
  };
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  Color _statusColor(String s) => switch (s) {
    'Chờ xác nhận' => AppColors.warning, 'Đang chuẩn bị' => AppColors.info,
    'Đang giao' => AppColors.primary, 'Hoàn thành' => AppColors.success,
    'Đã huỷ' => Colors.grey, _ => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(children: [
          Text(order['id'], style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(order['total'], style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(order['customer'], style: AppTextStyles.bodySmall),
              const Spacer(),
              Text('${order['items']} sản phẩm', style: AppTextStyles.labelSmall),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(order['time'], style: AppTextStyles.labelSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _statusColor(order['status']).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(order['status'], style: TextStyle(fontSize: 11, color: _statusColor(order['status']))),
              ),
            ]),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
