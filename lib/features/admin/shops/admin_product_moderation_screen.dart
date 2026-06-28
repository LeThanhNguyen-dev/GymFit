import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

final _productsByStatusProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, String status) async {
  final supabase = ref.watch(supabaseClientProvider);
  final rows = await supabase
      .from('products')
      .select('id, name, seller_id, created_at, short_description, base_price')
      .eq('status', status)
      .order('created_at', ascending: false);
  return rows.map((r) => Map<String, dynamic>.from(r)).toList();
});

class AdminProductModerationScreen extends ConsumerStatefulWidget {
  const AdminProductModerationScreen({super.key});
  @override
  ConsumerState<AdminProductModerationScreen> createState() => _AdminProductModerationScreenState();
}

class _AdminProductModerationScreenState extends ConsumerState<AdminProductModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt sản phẩm'), bottom: TabBar(
        controller: _tabCtrl,
        tabs: 'Chờ duyệt|Đã duyệt|Từ chối|Vi phạm'.split('|').map((t) => Tab(text: t)).toList(),
      )),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildList('pending'), _buildList('active'), _buildList('rejected'), _buildList('inactive'),
      ]),
    );
  }

  Widget _buildList(String status) {
    return ref.watch(_productsByStatusProvider(status)).when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('Không có kết quả'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => Card(
            child: ListTile(
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image)),
              title: Text(items[i]['name'] as String, style: AppTextStyles.bodyMedium),
              subtitle: Text('Shop: ${items[i]['seller_id']} - ${items[i]['created_at']?.toString().substring(0, 10)}', style: AppTextStyles.labelSmall),
              trailing: status == 'pending'
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: () => _approveProduct(items[i])),
                      IconButton(icon: const Icon(Icons.cancel, color: AppColors.error), onPressed: () => _showRejectDialog(items[i])),
                    ])
                  : const Icon(Icons.chevron_right),
              onTap: () => _showProductDetail(items[i], status),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Future<void> _approveProduct(Map<String, dynamic> item) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('products').update({'status': 'active'}).eq('id', item['id']);
    ref.invalidate(_productsByStatusProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt sản phẩm')));
  }

  void _showRejectDialog(Map<String, dynamic> item) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Từ chối sản phẩm'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Lý do từ chối...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () async {
          Navigator.pop(context);
          final supabase = ref.read(supabaseClientProvider);
          await supabase.from('products').update({'status': 'rejected', 'short_description': ctrl.text}).eq('id', item['id']);
          ref.invalidate(_productsByStatusProvider);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối sản phẩm')));
        }, child: const Text('Từ chối'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ));
  }

  void _showProductDetail(Map<String, dynamic> item, String status) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 200, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: AppSpacing.md),
          Text(item['name'], style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Shop ID: ${item['seller_id']}', style: AppTextStyles.bodySmall),
          Text('Giá: ${item['base_price']}₫', style: AppTextStyles.bodySmall),
          if (item['short_description'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(item['short_description'], style: AppTextStyles.bodySmall),
          ],
          const Spacer(),
          if (status == 'pending') Row(children: [
            Expanded(child: FilledButton(onPressed: () {
              Navigator.pop(context);
              _approveProduct(item);
            }, child: const Text('Duyệt'), style: FilledButton.styleFrom(backgroundColor: AppColors.success))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(context); _showRejectDialog(item); }, child: const Text('Từ chối'))),
          ]),
        ]),
      ),
    ));
  }
}
