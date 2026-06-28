import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

final _shopsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('shop_registrations')
      .select('id, shop_name, full_name, phone_number, status, submitted_at, user_id')
      .order('submitted_at', ascending: false);
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

final _pendingProductsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('products')
      .select('id, name, seller_id, created_at, short_description, base_price')
      .eq('status', 'pending');
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

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
    return ref.watch(_shopsListProvider).when(
      data: (shops) {
        final filtered = shops.where((s) =>
          s['status'] == status &&
          (_search.isEmpty ||
            s['shop_name'].toString().toLowerCase().contains(_search) ||
            s['full_name'].toString().toLowerCase().contains(_search))
        ).toList();
        if (filtered.isEmpty) return const Center(child: Text('Không có kết quả'));
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _ShopCard(
            data: filtered[i],
            onTap: () => context.go('/admin/shops/${filtered[i]['id']}'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildViolations() {
    return ref.watch(_pendingProductsProvider).when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('Không có sản phẩm vi phạm'));
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => Card(
            child: ListTile(
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
              title: Text(items[i]['name'] as String, style: AppTextStyles.bodyMedium),
              subtitle: Text('Shop ID: ${items[i]['seller_id']}', style: AppTextStyles.labelSmall),
              trailing: PopupMenuButton(itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                const PopupMenuItem(value: 'remove', child: Text('Gỡ khỏi sàn')),
                const PopupMenuItem(value: 'approve', child: Text('Duyệt')),
              ], onSelected: (v) async {
                if (v == 'approve') {
                  final supabase = ref.read(supabaseClientProvider);
                  await supabase.from('products').update({'status': 'active'}).eq('id', items[i]['id']);
                  ref.invalidate(_pendingProductsProvider);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt sản phẩm')));
                } else if (v == 'remove') {
                  final supabase = ref.read(supabaseClientProvider);
                  await supabase.from('products').update({'status': 'rejected'}).eq('id', items[i]['id']);
                  ref.invalidate(_pendingProductsProvider);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ sản phẩm')));
                } else if (v == 'view') {
                  _showProductDetail(items[i]);
                }
              }),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  void _showProductDetail(Map<String, dynamic> item) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal) + EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item['name'], style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        Text('Shop ID: ${item['seller_id']}', style: AppTextStyles.bodySmall),
        Text('Giá: ${item['base_price']}₫', style: AppTextStyles.bodySmall),
        if (item['short_description'] != null) Text(item['short_description'], style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () async {
            final supabase = ref.read(supabaseClientProvider);
            await supabase.from('products').update({'status': 'active'}).eq('id', item['id']);
            ref.invalidate(_pendingProductsProvider);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Duyệt'), style: FilledButton.styleFrom(backgroundColor: AppColors.success))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))),
        ]),
      ]),
    ));
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColors = {'pending': AppColors.warning, 'approved': AppColors.success, 'rejected': AppColors.error};
    final statusLabels = {'pending': 'Chờ duyệt', 'approved': 'Đã duyệt', 'rejected': 'Từ chối'};
    final status = data['status'] as String? ?? 'pending';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainerHighest,
          child: const Icon(Icons.store, color: Colors.grey),
        ),
        title: Text(data['shop_name'] ?? '', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['full_name']} - ${data['submitted_at']?.toString().substring(0, 10) ?? ''}', style: AppTextStyles.labelSmall),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (statusColors[status] ?? Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabels[status] ?? '', style: AppTextStyles.labelSmall.copyWith(
                color: statusColors[status] ?? Colors.grey, fontSize: 11,
              )),
            ),
          ]),
        ]),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
