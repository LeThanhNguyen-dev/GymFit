import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
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
          child: Consumer(
            builder: (context, ref, child) {
              final supabase = ref.watch(supabaseClientProvider);
              return FutureBuilder<List<dynamic>>(
                future: supabase.rpc('get_admin_payout_requests').then((res) => List<dynamic>.from(res ?? [])),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  
                  final allItems = snapshot.data ?? [];
                  final pending = allItems.where((i) => i['status'] == 'pending').toList();
                  final approved = allItems.where((i) => i['status'] == 'approved' || i['status'] == 'completed').toList();
                  final rejected = allItems.where((i) => i['status'] == 'rejected').toList();

                  Widget buildList(List<dynamic> items) {
                    if (items.isEmpty) return const Center(child: Text('Không có yêu cầu nào.'));
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                        final fmtAmount = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
                        final date = DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16);
                        
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerHighest, child: const Icon(Icons.payments, color: Colors.grey)),
                            title: Text('${item['seller_name']} - $fmtAmount₫', style: AppTextStyles.bodyMedium),
                            subtitle: Text('${item['bank_name']} - $date', style: AppTextStyles.labelSmall),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showWithdrawalDetail(item, supabase),
                          ),
                        );
                      },
                    );
                  }

                  return TabBarView(
                    children: [
                      buildList(pending),
                      buildList(approved),
                      buildList(rejected),
                    ],
                  );
                },
              );
            },
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

  void _showWithdrawalDetail(Map<String, dynamic> wd, dynamic supabase) {
    final amount = double.tryParse(wd['amount']?.toString() ?? '0') ?? 0.0;
    final fmtAmount = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final isPending = wd['status'] == 'pending';

    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Rút tiền - ${wd['seller_name']}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Số tiền: $fmtAmount₫', style: AppTextStyles.bodyMedium),
        Text('Ngân hàng: ${wd['bank_name']}', style: AppTextStyles.bodySmall),
        Text('Số TK: ${wd['account_number']}', style: AppTextStyles.bodySmall),
        Text('Chủ TK: ${wd['account_holder']}', style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Text('Trạng thái: ${wd['status']}', style: AppTextStyles.bodySmall),
        if (wd['rejection_reason'] != null) ...[
          const Divider(),
          Text('Lý do từ chối: ${wd['rejection_reason']}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ]
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        if (isPending) ...[
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.rpc('admin_update_payout_status', params: {
                  'p_payout_id': wd['id'],
                  'p_status': 'rejected',
                  'p_reason': 'Thông tin không hợp lệ',
                });
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            }, 
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.rpc('admin_update_payout_status', params: {
                  'p_payout_id': wd['id'],
                  'p_status': 'completed',
                });
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            }, 
            child: const Text('Đã chuyển khoản'),
          ),
        ]
      ],
    ));
  }

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
