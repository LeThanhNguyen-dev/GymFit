import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminFinanceScreen extends ConsumerStatefulWidget {
  const AdminFinanceScreen({super.key});
  @override
  ConsumerState<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends ConsumerState<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài chính & Duyệt'), bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Yêu cầu rút tiền'),
          Tab(text: 'Doanh thu sàn'),
          Tab(text: 'Lịch sử GD'),
          Tab(text: 'Cấu hình phí'),
        ],
      )),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildWithdrawals(),
        _buildRevenue(),
        _buildTransactions(),
        _buildFeeConfig(),
      ]),
    );
  }

  Widget _buildWithdrawals() {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: 'Chờ duyệt|Đã duyệt|Từ chối'.split('|').map((t) => Tab(text: t)).toList()),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            itemCount: _mockWithdrawals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, child: const Icon(Icons.payments, color: Colors.grey)),
                title: Text('${_mockWithdrawals[i]['shop']} - ${_mockWithdrawals[i]['amount']}', style: AppTextStyles.bodyMedium),
                subtitle: Text('${_mockWithdrawals[i]['bank']} - ${_mockWithdrawals[i]['date']}', style: AppTextStyles.labelSmall),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWithdrawalDetail(_mockWithdrawals[i]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRevenue() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: [
              Text('Tổng phí sàn (Tháng 6/2026)', style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text('156.2M₫', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
              const SizedBox(height: AppSpacing.md),
              _revenueRow('Phí giao dịch', '98.5M₫', 0.63),
              _revenueRow('Phí quảng cáo', '42.3M₫', 0.27),
              _revenueRow('Phí khác', '15.4M₫', 0.10),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Doanh thu 12 tháng', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(height: 180, child: _buildRevenueChart()),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Xuất báo cáo CSV'))),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return CustomPaint(painter: _MockRevenuePainter(), size: const Size(double.infinity, 180));
  }

  Widget _revenueRow(String label, String amount, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(amount, style: AppTextStyles.bodyMedium),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct, backgroundColor: AppColors.surfaceContainerHighest),
      ]),
    );
  }

  Widget _buildTransactions() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      itemCount: _mockTransactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        leading: Icon(_mockTransactions[i]['type'] == 'fee' ? Icons.payments : Icons.swap_horiz, color: _mockTransactions[i]['type'] == 'fee' ? AppColors.success : AppColors.primary, size: 20),
        title: Text(_mockTransactions[i]['desc'] as String, style: AppTextStyles.bodySmall),
        subtitle: Text(_mockTransactions[i]['id'] as String, style: AppTextStyles.labelSmall),
        trailing: Text(_mockTransactions[i]['amount'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFeeConfig() {
    final feeCtrl = TextEditingController(text: '2.5');
    final catFees = ['Thể thao: 2%', 'Dinh dưỡng: 3%', 'Phụ kiện: 2.5%'];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phí sàn mặc định (%)', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: '%')),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () {}, child: const Text('Lưu'))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phí theo danh mục', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              ...catFees.map((f) => ListTile(
                title: Text(f, style: AppTextStyles.bodySmall),
                trailing: IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                dense: true,
              )),
            ]),
          ),
        ),
      ],
    );
  }

  void _showWithdrawalDetail(Map<String, dynamic> wd) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Rút tiền - ${wd['shop']}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Số tiền: ${wd['amount']}', style: AppTextStyles.bodyMedium),
        Text('Ngân hàng: ${wd['bank']}', style: AppTextStyles.bodySmall),
        Text('Số TK: 1234 5678 9012', style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Text('Số dư hiện tại: 28.5M₫', style: AppTextStyles.bodySmall),
        const Divider(),
        Text('Lịch sử rút gần nhất:', style: AppTextStyles.labelSmall),
        Text('10/06: -5.000.000₫ (Thành công)', style: AppTextStyles.labelSmall),
        Text('01/06: -3.000.000₫ (Thành công)', style: AppTextStyles.labelSmall),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Từ chối')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Duyệt & Chuyển khoản')),
      ],
    ));
  }

  static const _mockWithdrawals = [
    {'shop': 'SportLife', 'amount': '10.000.000₫', 'bank': 'VCB - 1234 5678', 'date': '15/06'},
    {'shop': 'Iron Gym', 'amount': '5.000.000₫', 'bank': 'TCB - 9876 5432', 'date': '14/06'},
    {'shop': 'Yoga Center', 'amount': '3.200.000₫', 'bank': 'MB - 4567 8901', 'date': '13/06'},
  ];

  static const _mockTransactions = [
    {'id': '#TXN001', 'desc': 'Phí giao dịch - SportLife', 'amount': '+2.500.000₫', 'type': 'fee'},
    {'id': '#TXN002', 'desc': 'Phí giao dịch - Iron Gym', 'amount': '+1.200.000₫', 'type': 'fee'},
    {'id': '#TXN003', 'desc': 'Rút tiền - SportLife', 'amount': '-10.000.000₫', 'type': 'withdraw'},
    {'id': '#TXN004', 'desc': 'Rút tiền - Iron Gym', 'amount': '-5.000.000₫', 'type': 'withdraw'},
    {'id': '#TXN005', 'desc': 'Phí quảng cáo - Yoga Center', 'amount': '+800.000₫', 'type': 'fee'},
  ];
}

class _MockRevenuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.success.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final linePaint = Paint()..color = AppColors.success..strokeWidth = 2;
    final values = [0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.85, 1.0];
    final dx = size.width / (values.length - 1);
    final path = Path();
    path.moveTo(0, size.height * (1 - values[0]));
    for (var i = 1; i < values.length; i++) path.lineTo(i * dx, size.height * (1 - values[i]));
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, linePaint..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
