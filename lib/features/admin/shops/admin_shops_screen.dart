import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});
  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Shop'), bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabs: 'Chờ duyệt|Đã duyệt|Từ chối|Vi phạm'.split('|').map((t) => Tab(text: t)).toList(),
      )),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm shop...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
          _buildViolations(),
        ])),
      ]),
    );
  }

  Widget _buildList(String status) {
    final shops = _mockShops.where((s) => s['status'] == status && (_search.isEmpty || s['name'].toString().toLowerCase().contains(_search) || s['owner'].toString().toLowerCase().contains(_search))).toList();
    return shops.isEmpty
        ? const Center(child: Text('Không có kết quả'))
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _ShopCard(
              data: shops[i],
              onTap: () => context.go('/admin/shops/${shops[i]['id']}'),
            ),
          );
  }

  Widget _buildViolations() {
    final items = _mockViolations;
    return items.isEmpty
        ? const Center(child: Text('Không có sản phẩm vi phạm'))
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
                title: Text(items[i]['name'] as String, style: AppTextStyles.bodyMedium),
                subtitle: Text('${items[i]['shop']} - ${items[i]['reason']}', style: AppTextStyles.labelSmall),
                trailing: PopupMenuButton(itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                  const PopupMenuItem(value: 'remove', child: Text('Gỡ khỏi sàn')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Bỏ qua')),
                ], onSelected: (v) {
                  if (v == 'view') _showViolationDetail(items[i]);
                }),
              ),
            ),
          );
  }

  void _showViolationDetail(Map<String, dynamic> item) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item['name'], style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text('Shop: ${item['shop']}', style: AppTextStyles.bodySmall),
        Text('Lý do: ${item['reason']}', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Gỡ khỏi sàn'), style: FilledButton.styleFrom(backgroundColor: AppColors.error))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Bỏ qua'))),
        ]),
      ]),
    ));
  }

  static const _mockShops = [
    {'id': '1', 'name': 'GymFit Store', 'owner': 'Nguyễn Văn A', 'status': 'pending', 'date': '15/06', 'items': 0, 'avatar': null, 'revenue': '0₫'},
    {'id': '2', 'name': 'Fitness Pro', 'owner': 'Trần Thị B', 'status': 'pending', 'date': '14/06', 'items': 0, 'avatar': null, 'revenue': '0₫'},
    {'id': '3', 'name': 'SportLife', 'owner': 'Lê Văn C', 'status': 'approved', 'date': '10/06', 'items': 45, 'avatar': null, 'revenue': '156.2M₫'},
    {'id': '4', 'name': 'Iron Gym', 'owner': 'Phạm Thị D', 'status': 'approved', 'date': '01/06', 'items': 32, 'avatar': null, 'revenue': '89.5M₫'},
    {'id': '5', 'name': 'Muscle Up', 'owner': 'Hoàng Văn E', 'status': 'rejected', 'date': '12/06', 'items': 0, 'avatar': null, 'revenue': '0₫'},
    {'id': '6', 'name': 'Yoga Center', 'owner': 'Mai Thị F', 'status': 'approved', 'date': '20/05', 'items': 28, 'avatar': null, 'revenue': '45.8M₫'},
  ];

  static const _mockViolations = [
    {'name': 'Protein Powder X', 'shop': 'SportLife', 'reason': 'Sản phẩm không đúng mô tả', 'id': '1'},
    {'name': 'Tạ tập 20kg', 'shop': 'Iron Gym', 'reason': 'Hàng nhái', 'id': '2'},
  ];
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColors = {'pending': AppColors.warning, 'approved': AppColors.success, 'rejected': AppColors.error};
    final statusLabels = {'pending': 'Chờ duyệt', 'approved': 'Đã duyệt', 'rejected': 'Từ chối'};
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainerHighest,
          child: data['avatar'] != null ? null : const Icon(Icons.store, color: Colors.grey),
        ),
        title: Text(data['name'], style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['owner']} - ${data['date']}', style: AppTextStyles.labelSmall),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (statusColors[data['status']] ?? Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabels[data['status']] ?? '', style: AppTextStyles.labelSmall.copyWith(
                color: statusColors[data['status']] ?? Colors.grey, fontSize: 11,
              )),
            ),
            if (data['items'] > 0) ...[
              const SizedBox(width: 8),
              Text('${data['items']} SP | ${data['revenue']}', style: AppTextStyles.labelSmall),
            ],
          ]),
        ]),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
