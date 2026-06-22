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
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  // Mock withdraw requests but store bank details in Shop Registration Metadata
  Map<String, dynamic> _bankDetails = {'bank_name': '', 'account_number': '', 'account_holder': ''};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBankAccount(dynamic reg) async {
    try {
      // Create new metadata or merge
      final metadata = {...reg.metadata, 'bank': _bankDetails};

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

          // Load bank details from metadata
          final meta = reg.metadata;
          if (meta['bank'] != null) {
            _bankDetails = Map<String, dynamic>.from(meta['bank']);
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: userId == null
                ? Future.value({'revenue': 0.0, 'completed_orders_count': 0})
                : supabase.rpc('get_store_stats', params: {'p_seller_id': userId}).then((res) => Map<String, dynamic>.from(res ?? {})),
            builder: (ctx, snapshot) {
              final stats = snapshot.data ?? {'revenue': 0.0, 'completed_orders_count': 0};
              final revenue = double.tryParse(stats['revenue']?.toString() ?? '0') ?? 0.0;
              final formattedRevenue = revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

              return Column(
                children: [
                  _buildBalanceOverview(formattedRevenue),
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabs: 'Tổng quan|Rút tiền|Lịch sử|Ngân hàng'.split('|').map((t) => Tab(text: t)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabCtrl, children: [
                      _buildOverview(formattedRevenue, stats['order_count']?.toString() ?? '0'),
                      _buildWithdraw(reg, revenue),
                      _buildHistory(userId, supabase),
                      _buildBankAccounts(reg),
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
          Text('Tổng doanh thu đã nhận', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('$formattedRevenue₫', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _balanceItem('Đã quyết toán', '$formattedRevenue₫'),
            _balanceItem('Khả dụng', '$formattedRevenue₫'),
          ]),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
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

  Widget _buildWithdraw(dynamic reg, double maxAmount) {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Text('Số dư khả dụng để rút: ${maxAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫', style: AppTextStyles.bodyMedium),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _amountCtrl,
        decoration: const InputDecoration(labelText: 'Số tiền rút (₫)', border: OutlineInputBorder(), prefixText: '₫ '),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Tài khoản nhận', border: OutlineInputBorder()),
        initialValue: _bankDetails['account_number']?.isNotEmpty == true ? '1' : null,
        items: [
          if (_bankDetails['account_number']?.isNotEmpty == true)
            DropdownMenuItem(
              value: '1',
              child: Text('${_bankDetails['bank_name']} • ${_bankDetails['account_number']}'),
            )
        ],
        onChanged: (_) {},
      ),
      const SizedBox(height: AppSpacing.lg),
      FilledButton.icon(
        onPressed: _isSubmitting || _bankDetails['account_number']?.isEmpty == true
            ? null
            : () async {
                final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                if (amount <= 0 || amount > maxAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền rút không hợp lệ!')));
                  return;
                }
                setState(() => _isSubmitting = true);
                // Mocking request submittal
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) {
                  setState(() => _isSubmitting = false);
                  _amountCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yêu cầu rút tiền đang được xử lý!')));
                }
              },
        icon: const Icon(Icons.send),
        label: const Text('Gửi yêu cầu rút tiền'),
      ),
    ]);
  }

  Widget _buildHistory(String? userId, dynamic supabase) {
    return FutureBuilder<List<dynamic>>(
      future: userId == null
          ? Future.value([])
          : supabase
              .from('order_items')
              .select('*, orders!inner(status, created_at), products!inner(seller_id)')
              .eq('products.seller_id', userId)
              .eq('orders.status', 'delivered'),
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

  Widget _buildBankAccounts(dynamic reg) {
    final bankCtrl = TextEditingController(text: _bankDetails['bank_name']);
    final accCtrl = TextEditingController(text: _bankDetails['account_number']);
    final holderCtrl = TextEditingController(text: _bankDetails['account_holder']);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('Thông tin tài khoản ngân hàng nhận tiền', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: bankCtrl,
          decoration: const InputDecoration(labelText: 'Tên ngân hàng (VD: Vietcombank)', border: OutlineInputBorder()),
          onChanged: (val) => _bankDetails['bank_name'] = val.trim(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: accCtrl,
          decoration: const InputDecoration(labelText: 'Số tài khoản', border: OutlineInputBorder()),
          onChanged: (val) => _bankDetails['account_number'] = val.trim(),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: holderCtrl,
          decoration: const InputDecoration(labelText: 'Tên chủ tài khoản', border: OutlineInputBorder()),
          onChanged: (val) => _bankDetails['account_holder'] = val.trim(),
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
