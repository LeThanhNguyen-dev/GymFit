import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';

final _shopDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, shopId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final row = await supabase
      .from('shop_registrations')
      .select('*')
      .eq('id', shopId)
      .maybeSingle();
  return row != null ? Map<String, dynamic>.from(row) : null;
});

final _shopProductsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('products')
      .select('id, name, base_price, total_sold, status')
      .eq('seller_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

final _shopPaymentsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, shopId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('payments')
      .select('id, amount, method, status, created_at')
      .eq('order_id', shopId)
      .order('created_at', ascending: false)
      .limit(50);
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

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
    final shopAsync = ref.watch(_shopDetailProvider(widget.shopId));
    return Scaffold(
      appBar: AppBar(title: Text('Shop #${widget.shopId}'), actions: [
        PopupMenuButton(itemBuilder: (_) => [
          const PopupMenuItem(value: 'suspend', child: Text('Tạm đình chỉ')),
          const PopupMenuItem(value: 'warn', child: Text('Gửi cảnh báo')),
        ], onSelected: _handleAction),
      ]),
      body: shopAsync.when(
        data: (shop) {
          if (shop == null) return const Center(child: Text('Không tìm thấy shop'));
          return Column(children: [
            _buildInfoHeader(shop),
            TabBar(controller: _tabCtrl, tabs: const [
              Tab(text: 'Sản phẩm'), Tab(text: 'Ví & Giao dịch'), Tab(text: 'Vi phạm'),
            ]),
            Expanded(child: TabBarView(controller: _tabCtrl, children: [
              _buildProducts(shop['user_id'] as String? ?? ''),
              _buildTransactions(shop['user_id'] as String? ?? ''),
              _buildViolations(),
            ])),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildInfoHeader(Map<String, dynamic> shop) {
    return Column(children: [
      Card(
        margin: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, AppSpacing.pageHorizontal, 0),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, radius: 24, child: const Icon(Icons.store, color: Colors.grey)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shop['shop_name'] ?? '', style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text('${shop['full_name']} - ${shop['phone_number']}', style: AppTextStyles.labelSmall),
              Text(shop['address'] ?? '', style: AppTextStyles.labelSmall),
            ])),
          ]),
        ),
      ),
      _buildStatsRow(shop),
    ]);
  }

  Widget _buildStatsRow(Map<String, dynamic> shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: Row(children: [
        _statCard('Trạng thái', shop['status']?.toString().toUpperCase() ?? ''),
        _statCard('Loại', shop['business_type']?.toString().toUpperCase() ?? ''),
        _statCard('Mã số thuế', shop['tax_code']?.toString() ?? 'N/A'),
        _statCard('Ngày đăng ký', shop['submitted_at']?.toString().substring(0, 10) ?? ''),
      ].expand((w) => [w, const SizedBox(width: AppSpacing.sm)]).toList()..removeLast()),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(child: Card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      child: Column(children: [
        Text(value, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
        Text(label, style: AppTextStyles.labelSmall),
      ]),
    )));
  }

  Widget _buildProducts(String userId) {
    if (userId.isEmpty) return const Center(child: Text('Không có dữ liệu'));
    return ref.watch(_shopProductsProvider(userId)).when(
      data: (products) {
        if (products.isEmpty) return const Center(child: Text('Không có sản phẩm'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
            title: Text(products[i]['name'] as String, style: AppTextStyles.bodyMedium),
            subtitle: Text('${products[i]['base_price']}₫ - Đã bán: ${products[i]['total_sold']}', style: AppTextStyles.labelSmall),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildTransactions(String userId) {
    if (userId.isEmpty) return const Center(child: Text('Không có dữ liệu'));
    return ref.watch(_shopPaymentsProvider(widget.shopId)).when(
      data: (txns) {
        if (txns.isEmpty) return const Center(child: Text('Chưa có giao dịch'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: txns.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final amount = (txns[i]['amount'] as num?)?.toDouble() ?? 0;
            return ListTile(
              leading: Icon(Icons.arrow_downward, color: AppColors.success, size: 20),
              title: Text('${txns[i]['method']} - ${txns[i]['status']}', style: AppTextStyles.bodySmall),
              subtitle: Text(txns[i]['created_at']?.toString().substring(0, 16) ?? '', style: AppTextStyles.labelSmall),
              trailing: Text(formatCurrency(amount), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildViolations() {
    return const Center(child: Text('Chưa có vi phạm'));
  }

  void _handleAction(String action) {
    if (action == 'suspend') {
      _showSuspendDialog();
    } else if (action == 'warn') _showWarnDialog();
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
          Expanded(child: ElevatedButton(onPressed: () => _confirmSuspend(reasonCtrl.text, 3), child: const Text('3 ngày'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () => _confirmSuspend(reasonCtrl.text, 7), child: const Text('7 ngày'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () => _confirmSuspend(reasonCtrl.text, 30), child: const Text('30 ngày'))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
      ],
    ));
  }

  void _confirmSuspend(String reason, int days) async {
    Navigator.pop(context);
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('shop_registrations').update({
      'metadata': {'suspended_until': DateTime.now().add(Duration(days: days)).toIso8601String(), 'suspend_reason': reason},
    }).eq('id', widget.shopId);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã tạm đình chỉ $days ngày')));
  }

  void _showWarnDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Gửi cảnh báo'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nội dung cảnh báo...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () async {
          Navigator.pop(context);
          final supabase = ref.read(supabaseClientProvider);
          await supabase.from('shop_registrations').update({
            'metadata': {'warning': ctrl.text, 'warned_at': DateTime.now().toIso8601String()},
          }).eq('id', widget.shopId);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi cảnh báo')));
        }, child: const Text('Gửi')),
      ],
    ));
  }
}
