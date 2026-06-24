import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTimeRange? _dateRange;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Đơn hàng'), actions: [
        IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDateRange),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm đơn hàng...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
          ),
        ),
        TabBar(controller: _tabCtrl, isScrollable: true, tabs: [
          const Tab(text: 'Đơn hàng'),
          const Tab(text: 'Khiếu nại'),
          Tab(text: _dateRange != null ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}' : 'Bộ lọc'),
        ]),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildOrderList(),
          _buildDisputeList(),
          _buildDateFilter(),
        ])),
      ]),
    );
  }

  Widget _buildOrderList() {
    final statuses = ['all', 'pending', 'confirmed', 'shipped', 'completed', 'cancelled', 'return'];
    return DefaultTabController(
      length: statuses.length,
      child: Column(children: [
        TabBar(
          isScrollable: true,
          tabs: ['Tất cả', 'Chờ', 'Đã XN', 'Đang gửi', 'HT', 'Đã huỷ', 'Trả hàng'].map((t) => Tab(text: t)).toList(),
          onTap: (_) {},
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: _mockOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _orderStatusColor(_mockOrders[i]['status'] as String).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.receipt_long, color: _orderStatusColor(_mockOrders[i]['status'] as String), size: 20),
                ),
                title: Text(_mockOrders[i]['id'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('${_mockOrders[i]['buyer']} - ${_mockOrders[i]['shop']} - ${_mockOrders[i]['total']}', style: AppTextStyles.labelSmall),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_mockOrders[i]['time'] as String, style: AppTextStyles.labelSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: _orderStatusColor(_mockOrders[i]['status'] as String).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(_mockOrders[i]['status'] as String, style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: _orderStatusColor(_mockOrders[i]['status'] as String))),
                  ),
                ]),
                onTap: () => context.go(
                  RouteNames.adminOrderDetailPath.replaceAll(
                    ':id',
                    _mockOrders[i]['id'].toString(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDisputeList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: _mockDisputes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => Card(
        child: ListTile(
          leading: Icon(Icons.report, color: Colors.deepOrange, size: 28),
          title: Text('Đơn #${_mockDisputes[i]['order']}', style: AppTextStyles.bodyMedium),
          subtitle: Text('${_mockDisputes[i]['buyer']} vs ${_mockDisputes[i]['shop']} - ${_mockDisputes[i]['type']}', style: AppTextStyles.labelSmall),
          trailing: Text(_mockDisputes[i]['date'] as String, style: AppTextStyles.labelSmall),
          onTap: () => _showDisputeDetail(_mockDisputes[i]),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Chọn khoảng thời gian', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(onPressed: _pickDateRange, icon: const Icon(Icons.date_range), label: const Text('Chọn ngày')),
      ]),
    );
  }

  void _pickDateRange() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime.now());
    if (range != null) setState(() => _dateRange = range);
  }

  void _showDisputeDetail(Map<String, dynamic> dispute) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Khiếu nại #${dispute['order']}', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('Người mua: ${dispute['buyer']}', style: AppTextStyles.bodySmall),
          Text('Shop: ${dispute['shop']}', style: AppTextStyles.bodySmall),
          Text('Loại: ${dispute['type']}', style: AppTextStyles.bodySmall),
          Text('Nội dung: Sản phẩm không đúng mô tả, đề nghị hoàn tiền', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          const Text('Bằng chứng:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 80,
            child: ListView(scrollDirection: Axis.horizontal, children: List.generate(3, (i) => Container(
              width: 80, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            ))),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Kết luận / Yêu cầu thêm bằng chứng...')),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Hoàn tiền buyer'), style: FilledButton.styleFrom(backgroundColor: AppColors.warning))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Giữ tiền cho shop'))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng khiếu nại'))),
        ]),
      ),
    );
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'shipped': return AppColors.primary;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'return': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  static const _mockOrders = [
    {'id': '#DH20260601', 'buyer': 'Nguyễn Văn A', 'shop': 'SportLife', 'total': '1.200.000₫', 'status': 'pending', 'time': '15/06 14:30'},
    {'id': '#DH20260602', 'buyer': 'Trần Thị B', 'shop': 'Iron Gym', 'total': '850.000₫', 'status': 'shipped', 'time': '14/06 09:15'},
    {'id': '#DH20260603', 'buyer': 'Lê Văn C', 'shop': 'Yoga Center', 'total': '2.100.000₫', 'status': 'completed', 'time': '13/06 16:45'},
    {'id': '#DH20260604', 'buyer': 'Phạm Thị D', 'shop': 'SportLife', 'total': '560.000₫', 'status': 'cancelled', 'time': '12/06 11:00'},
    {'id': '#DH20260605', 'buyer': 'Hoàng Văn E', 'shop': 'Iron Gym', 'total': '3.500.000₫', 'status': 'return', 'time': '11/06 08:30'},
  ];

  static const _mockDisputes = [
    {'order': 'DH20260605', 'buyer': 'Hoàng Văn E', 'shop': 'Iron Gym', 'type': 'Sản phẩm lỗi', 'date': '11/06'},
    {'order': 'DH20260603', 'buyer': 'Lê Văn C', 'shop': 'Yoga Center', 'type': 'Không đúng mô tả', 'date': '13/06'},
  ];
}
