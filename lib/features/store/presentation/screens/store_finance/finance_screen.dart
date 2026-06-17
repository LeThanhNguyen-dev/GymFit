import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài chính'), elevation: 0),
      body: Column(
        children: [
          _buildBalanceOverview(),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Tổng quan|Rút tiền|Lịch sử|Ngân hàng'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildOverview(), _buildWithdraw(), _buildHistory(), _buildBankAccounts(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceOverview() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      color: AppColors.primary,
      child: Column(
        children: [
          Text('Số dư khả dụng', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('28.450.000₫', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _balanceItem('Đang chờ', '12.000.000₫'),
            _balanceItem('Đã rút', '50.000.000₫'),
            _balanceItem('Có thể rút', '28.450.000₫'),
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

  Widget _buildOverview() {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Card(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tổng quan thu nhập', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _statRow('Tháng này', '18.200.000₫', '+15%'),
          _statRow('Tháng trước', '15.800.000₫', '-3%'),
        ]),
      )),
    ]);
  }

  Widget _statRow(String label, String value, String change) {
    final isUp = change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium),
        Text(change, style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 13)),
      ]),
    );
  }

  Widget _buildWithdraw() {
    final amountCtrl = TextEditingController();
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Số tiền rút (₫)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField(
        decoration: const InputDecoration(labelText: 'Tài khoản nhận', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: '1', child: Text('Vietcombank • 1234'))],
        onChanged: (_) {},
      ),
      const SizedBox(height: AppSpacing.lg),
      FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('Gửi yêu cầu rút tiền')),
    ]);
  }

  Widget _buildHistory() {
    final txns = List.generate(10, (i) => _mockTxn(i));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: txns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        title: Text(txns[i]['label'], style: AppTextStyles.bodyMedium),
        subtitle: Text(txns[i]['time'], style: AppTextStyles.labelSmall),
        trailing: Text(txns[i]['amount'], style: TextStyle(
          fontWeight: FontWeight.bold,
          color: txns[i]['type'] == 'in' ? AppColors.success : AppColors.error,
        )),
      ),
    );
  }

  Map<String, dynamic> _mockTxn(int i) => [
    {'label': 'Đơn #DH2026001', 'amount': '+1.200.000₫', 'type': 'in', 'time': '15/06 14:30'},
    {'label': 'Rút tiền', 'amount': '-5.000.000₫', 'type': 'out', 'time': '14/06 10:00'},
    {'label': 'Đơn #DH2026002', 'amount': '+850.000₫', 'type': 'in', 'time': '13/06 09:15'},
    {'label': 'Rút tiền (thành công)', 'amount': '-10.000.000₫', 'type': 'out', 'time': '10/06 11:20'},
    {'label': 'Đơn #DH2026003', 'amount': '+2.100.000₫', 'type': 'in', 'time': '09/06 16:45'},
  ][i % 5];

  Widget _buildBankAccounts() {
    return ListView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), children: [
      Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.account_balance)),
          title: Text('Vietcombank', style: AppTextStyles.bodyMedium),
          subtitle: Text('1234 5678 9012 • Nguyễn Văn A', style: AppTextStyles.bodySmall),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () {}),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Thêm tài khoản ngân hàng')),
    ]);
  }
}
