import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

final storeOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await supabase.rpc('get_store_orders', params: {'p_seller_id': userId});
  return List<Map<String, dynamic>>.from(response);
});

class StoreOrderListScreen extends ConsumerStatefulWidget {
  const StoreOrderListScreen({super.key});
  @override
  ConsumerState<StoreOrderListScreen> createState() => _StoreOrderListScreenState();
}

class _StoreOrderListScreenState extends ConsumerState<StoreOrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(storeOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.sm, AppSpacing.pageHorizontal, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn hoặc tên khách...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchCtrl.clear(); _searchQuery = ''; }))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Chờ xác nhận|Đang chuẩn bị|Đang giao|Hoàn thành|Đã huỷ|Trả hàng'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // Apply search filter
                var filtered = orders;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((o) {
                    final orderNum = o['order_number']?.toString().toLowerCase() ?? '';
                    final fullName = o['shipping_full_name']?.toString().toLowerCase() ?? '';
                    return orderNum.contains(_searchQuery) || fullName.contains(_searchQuery);
                  }).toList();
                }

                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildOrderList(filtered.where((o) => o['status'] == 'pending').toList()),
                    _buildOrderList(filtered.where((o) => o['status'] == 'confirmed' || o['status'] == 'processing').toList()),
                    _buildOrderList(filtered.where((o) => o['status'] == 'shipped').toList()),
                    _buildOrderList(filtered.where((o) => o['status'] == 'delivered').toList()),
                    _buildOrderList(filtered.where((o) => o['status'] == 'cancelled').toList()),
                    _buildOrderList(filtered.where((o) => o['status'] == 'returned').toList()),
                  ],
                );
              },
              loading: () => const _OrdersShimmer(),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text('Lỗi: $err',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => ref.refresh(storeOrdersProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('Không có đơn hàng nào.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(storeOrdersProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _OrderCard(
          order: orders[i],
          onTap: () => context.push('${RouteNames.storeOrdersPath}/${orders[i]['id']}'),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.warning,
        'confirmed' || 'processing' => AppColors.info,
        'shipped' => AppColors.primary,
        'delivered' => AppColors.success,
        'cancelled' => AppColors.outline,
        _ => AppColors.error,
      };

  String _statusText(String s) => switch (s) {
        'pending' => 'Chờ xác nhận',
        'confirmed' || 'processing' => 'Đang chuẩn bị',
        'shipped' => 'Đang giao',
        'delivered' => 'Hoàn thành',
        'cancelled' => 'Đã huỷ',
        _ => 'Trả hàng',
      };

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final formattedTotal = total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    return Card(
      child: ListTile(
        title: Row(children: [
          Text(order['order_number']?.toString() ?? 'Đơn hàng', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('$formattedTotal₫', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(order['shipping_full_name']?.toString() ?? '', style: AppTextStyles.bodySmall),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(order['created_at'] != null ? DateTime.parse(order['created_at']!).toLocal().toString().substring(0, 16) : '', style: AppTextStyles.labelSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(order['status']?.toString() ?? '').withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText(order['status']?.toString() ?? ''),
                  style: TextStyle(fontSize: 11, color: _statusColor(order['status']?.toString() ?? ''), fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _OrdersShimmer extends StatefulWidget {
  const _OrdersShimmer();
  @override
  State<_OrdersShimmer> createState() => _OrdersShimmerState();
}

class _OrdersShimmerState extends State<_OrdersShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemBuilder: (_, _) => Container(
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _animation.value),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemCount: 4,
        );
      },
    );
  }
}
