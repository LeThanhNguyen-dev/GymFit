import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../orders/data/models/order_model.dart';
import '../dashboard/providers/dashboard_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String? _status;
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(adminOrderRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage orders')),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminOrders(
                status: _status,
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                sortBy: _sortBy,
                ascending: _ascending,
                page: _page,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data!;
                final orders = result.items;
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        title: Text(order.orderNumber),
                        subtitle: Text(
                          '${order.shippingFullName} - ${order.status.name}',
                        ),
                        trailing: Text('${order.totalAmount.round()}d'),
                        onTap: () => _showStatusDialog(order),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search by order number',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onFilterChanged(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...OrderStatus.values.map(
                (status) => DropdownMenuItem(
                  value: status.name,
                  child: Text(status.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _status = value;
              _page = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Mới nhất'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('total_amount', 'Amount low-high'),
      SortOption('total_amount_desc', 'Amount high-low'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SortDropdown(
        value: currentKey,
        options: sortOptions,
        onChanged: (key) {
          setState(() {
            if (key.endsWith('_desc')) {
              _sortBy = key.replaceAll('_desc', '');
              _ascending = false;
            } else {
              _sortBy = key;
              _ascending = true;
            }
            _page = 1;
          });
        },
      ),
    );
  }

  Widget _buildPagination() {
    return FutureBuilder(
      future: ref.read(adminOrderRepositoryProvider).getAdminOrders(
        status: _status,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
        pageSize: 20,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        final totalPages = (result.totalCount / 20).ceil();
        return PaginationBar(
          page: _page,
          totalPages: totalPages,
          totalItems: result.totalCount,
          onPageChanged: (p) => setState(() => _page = p),
        );
      },
    );
  }

  Future<void> _showStatusDialog(OrderModel order) async {
    var status = order.status;
    final note = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(order.orderNumber),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<OrderStatus>(
                initialValue: status,
                items: OrderStatus.values
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setLocalState(() => status = value ?? status),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final userId = ref
                    .read(supabaseClientProvider)
                    .auth
                    .currentUser
                    ?.id;
                await ref
                    .read(adminOrderRepositoryProvider)
                    .updateOrderStatus(
                      order.id,
                      status,
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                      changedBy: userId,
                    );
                if (mounted) setState(() {});
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
