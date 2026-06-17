import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminShopDetailScreen extends ConsumerStatefulWidget {
  const AdminShopDetailScreen({super.key, required this.shopId});
  final String shopId;
  @override
  ConsumerState<AdminShopDetailScreen> createState() => _AdminShopDetailScreenState();
}

class _AdminShopDetailScreenState extends ConsumerState<AdminShopDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop #${widget.shopId}'), actions: [
        PopupMenuButton(itemBuilder: (_) => [
          const PopupMenuItem(value: 'suspend', child: Text('Tạm đình chỉ')),
          const PopupMenuItem(value: 'ban', child: Text('Khoá vĩnh viễn')),
          const PopupMenuItem(value: 'warn', child: Text('Gửi cảnh báo')),
          const PopupMenuItem(value: 'unsuspend', child: Text('Gỡ đình chỉ')),
        ], onSelected: _handleAction),
      ]),
      body: Column(children: [
        _buildInfoHeader(),
        TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Sản phẩm'), Tab(text: 'Ví & Giao dịch'), Tab(text: 'Vi phạm'),
        ]),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildProducts(), _buildTransactions(), _buildViolations(),
        ])),
      ]),
    );
  }

  Widget _buildInfoHeader() {
    return Column(children: [
      Card(
        margin: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, 0),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, radius: 24, child: const Icon(Icons.store, color: Colors.grey)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SportLife', style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text('Lê Văn C - 0901 234 567', style: AppTextStyles.labelSmall),
              Text('123 Nguyễn Huệ, Q.1, TP.HCM', style: AppTextStyles.labelSmall),
            ])),
          ]),
        ),
      ),
      _buildStatsRow(),
    ]);
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: Row(children: [
        _statCard('Doanh thu', '156.2M₫'),
        _statCard('Đơn hàng', '312'),
        _statCard('Đánh giá', '4.5★'),
        _statCard('Huỷ đơn', '2.3%'),
      ].expand((w) => [w, const SizedBox(width: AppSpacing.sm)]).toList()..removeLast()),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(child: Card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      child: Column(children: [
        Text(value, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.labelSmall),
      ]),
    )));
  }

  Widget _buildProducts() {
    final products = List.generate(5, (i) => _mockProduct(i));
    return products.isEmpty
        ? const Center(child: Text('Không có sản phẩm'))
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
              title: Text(products[i], style: AppTextStyles.bodyMedium),
              subtitle: Text('12.5M₫', style: AppTextStyles.labelSmall),
              trailing: PopupMenuButton(itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Text('Xem')),
                const PopupMenuItem(value: 'hide', child: Text('Ẩn sản phẩm')),
              ]),
            ),
          );
  }

  Widget _buildTransactions() {
    final txns = ['Rút tiền -10.000.000₫ (15/06)', 'Rút tiền -5.000.000₫ (10/06)', 'Thanh toán đơn +1.200.000₫ (08/06)'];
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        leading: Icon(txns[i].startsWith('Rút') ? Icons.arrow_upward : Icons.arrow_downward, color: txns[i].startsWith('Rút') ? AppColors.error : AppColors.success, size: 20),
        title: Text(txns[i], style: AppTextStyles.bodySmall),
      ),
    );
  }

  Widget _buildViolations() {
    return const Center(child: Text('Chưa có vi phạm'));
  }

  void _handleAction(String action) {
    if (action == 'suspend') _showSuspendDialog();
    else if (action == 'ban') _showBanDialog();
    else if (action == 'warn') _showWarnDialog();
    else if (action == 'unsuspend') _showUnsuspendDialog();
  }

  void _showSuspendDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Tạm đình chỉ shop'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Nhập lý do tạm đình chỉ:'),
        const SizedBox(height: 8),
        TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do...')),
        const SizedBox(height: 8),
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
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận')),
      ],
    ));
  }

  void _showBanDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Khoá vĩnh viễn'),
      content: const Text('Bạn có chắc chắn muốn khoá vĩnh viễn shop này? Hành động này không thể hoàn tác.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Khoá'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ));
  }

  void _showWarnDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Gửi cảnh báo'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nội dung cảnh báo...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Gửi')),
      ],
    ));
  }

  void _showUnsuspendDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Gỡ đình chỉ'),
      content: const Text('Bạn có muốn gỡ đình chỉ cho shop này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xác nhận', style: TextStyle(color: Colors.white),),),
      ],
    ));
  }

  String _mockProduct(int i) => ['Gym Bag Pro', 'Protein Powder', 'Tạ tay 10kg', 'Yoga Mat', 'Bình nước thể thao'][i];
}
