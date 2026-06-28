import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../register_shop/providers/shop_registration_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _bankNameCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bankNameCtrl.dispose();
    _accCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBankAccount(dynamic reg) async {
    try {
      final metadata = {
        ...reg.metadata,
        'bank': {
          'bank_name': _bankNameCtrl.text.trim(),
          'account_number': _accCtrl.text.trim(),
          'account_holder': _holderCtrl.text.trim(),
        }
      };
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('shop_registrations').update({'metadata': metadata}).eq('id', reg.id);
      ref.invalidate(myShopRegistrationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thông tin ngân hàng thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regAsync = ref.watch(myShopRegistrationProvider);
    final supabase = ref.watch(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài chính'), elevation: 0),
      body: regAsync.when(
        data: (reg) {
          if (reg == null) {
            return const Center(child: Text('Đang tải thông tin Shop...'));
          }

          final meta = reg.metadata;
          final bankDetails = meta['bank'] != null ? Map<String, dynamic>.from(meta['bank']) : <String, dynamic>{};

          return FutureBuilder<Map<String, dynamic>>(
            future: userId == null
                ? Future.value({'revenue': 0.0, 'order_count': 0, 'product_count': 0, 'out_of_stock_count': 0})
                : supabase.rpc('get_store_stats', params: {'p_seller_id': userId}).then((res) => Map<String, dynamic>.from(res ?? {})),
            builder: (ctx, snapshot) {
              final stats = snapshot.data ?? {'revenue': 0.0, 'order_count': 0};
              final revenue = double.tryParse(stats['revenue']?.toString() ?? '0') ?? 0.0;
              final formattedRevenue = revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
              final orderCount = stats['order_count']?.toString() ?? '0';

              return Column(
                children: [
                  _buildBalanceOverview(formattedRevenue),
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabs: 'Tổng quan|Lịch sử|Ngân hàng'.split('|').map((t) => Tab(text: t)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabCtrl, children: [
                      _buildOverview(formattedRevenue, orderCount),
                      _buildHistory(userId, supabase),
                      _buildBankAccounts(reg, bankDetails),
                    ]),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildBalanceOverview(String formattedRevenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      color: AppColors.primary,
      child: Column(
        children: [
          Text('Tổng doanh thu', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('$formattedRevenue₫', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOverview(String formattedRevenue, String totalOrders) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng quan thu nhập', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _statRow('Doanh thu tích luỹ', '$formattedRevenue₫'),
            _statRow('Tổng đơn hàng thành công', totalOrders),
          ]),
        ),
      ),
    ]);
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildHistory(String? userId, dynamic supabase) {
    return FutureBuilder<List<dynamic>>(
      future: userId == null
          ? Future.value([])
          : supabase
              .from('order_items')
              .select('*, orders!inner(status, created_at), products!inner(seller_id)')
              .eq('products.seller_id', userId)
              .eq('orders.status', 'delivered')
              .order('created_at', ascending: false),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử giao dịch.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = items[i];
            final price = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
            final formattedPrice = price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
            final date = item['orders'] != null ? DateTime.parse(item['orders']['created_at']).toLocal().toString().substring(0, 16) : '';

            return ListTile(
              title: Text(item['product_name']?.toString() ?? 'Doanh thu sản phẩm', style: AppTextStyles.bodyMedium),
              subtitle: Text(date, style: AppTextStyles.labelSmall),
              trailing: Text('+$formattedPrice₫', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
            );
          },
        );
      },
    );
  }

  Widget _buildBankAccounts(dynamic reg, Map<String, dynamic> bankDetails) {
    _bankNameCtrl.text = bankDetails['bank_name'] ?? '';
    _accCtrl.text = bankDetails['account_number'] ?? '';
    _holderCtrl.text = bankDetails['account_holder'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('Thông tin tài khoản ngân hàng nhận tiền', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bankNameCtrl,
          decoration: const InputDecoration(labelText: 'Tên ngân hàng (VD: Vietcombank)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _accCtrl,
          decoration: const InputDecoration(labelText: 'Số tài khoản', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _holderCtrl,
          decoration: const InputDecoration(labelText: 'Tên chủ tài khoản', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _saveBankAccount(reg),
          child: const Text('Lưu thông tin ngân hàng'),
        ),
      ],
    );
  }
}
