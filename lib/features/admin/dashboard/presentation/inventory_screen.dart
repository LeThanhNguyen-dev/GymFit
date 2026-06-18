import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../../../shared/widgets/sort_dropdown.dart';
import '../data/models/admin_dashboard_models.dart';
import '../providers/dashboard_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _stockLevel = 'all';
  String _sortBy = 'quantity';
  bool _ascending = true;
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
    final lowStock = ref.watch(lowStockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          _buildFilterRow(lowStock),
          _buildSearchBar(),
          _buildSortRow(),
          Expanded(child: _buildListView()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AsyncValue<List<LowStockVariantModel>> lowStock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('All', 'all'),
            const SizedBox(width: 8),
            _buildChip('Low stock', 'low'),
            const SizedBox(width: 8),
            _buildChip('Out of stock', 'out'),
            const SizedBox(width: 16),
            Text('Low stock:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            lowStock.when(
              data: (items) => Text(
                '${items.length} items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              loading: () => const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _stockLevel == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _stockLevel = value;
          _page = 1;
        });
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search product or variant',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('quantity', 'Stock low-high'),
      SortOption('quantity_desc', 'Stock high-low'),
      SortOption('product_name', 'Product A-Z'),
      SortOption('product_name_desc', 'Product Z-A'),
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

  Widget _buildListView() {
    final repository = ref.read(inventoryRepositoryProvider);
    return FutureBuilder(
      future: repository.getInventoryVariants(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        stockLevel: _stockLevel == 'all' ? null : _stockLevel,
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        final items = result.items;
        if (items.isEmpty) {
          return const Center(child: Text('No variants found.'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = item.stock <= 5
                  ? Colors.red
                  : item.stock <= 10
                      ? Colors.amber.shade800
                      : null;
              return ListTile(
                leading: Icon(Icons.warehouse, color: color),
                title: Text(item.productName),
                subtitle: Text(item.variantName ?? item.sku ?? item.variantId),
                trailing: Text(
                  item.stock.toString(),
                  style: TextStyle(color: color),
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => _StockDialog(
                    variantId: item.variantId,
                    currentStock: item.stock,
                    variantName: item.productName,
                    onSaved: () => setState(() {}),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    final repository = ref.read(inventoryRepositoryProvider);
    return FutureBuilder(
      future: repository.getInventoryVariants(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        stockLevel: _stockLevel == 'all' ? null : _stockLevel,
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
}

class _StockDialog extends ConsumerStatefulWidget {
  const _StockDialog({
    required this.variantId,
    required this.currentStock,
    required this.variantName,
    this.onSaved,
  });

  final String variantId;
  final int currentStock;
  final String variantName;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends ConsumerState<_StockDialog> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.currentStock.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newQty = int.tryParse(_quantityController.text.trim()) ?? widget.currentStock;
    final diff = newQty - widget.currentStock;
    return AlertDialog(
      title: const Text('Update Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Variant: ${widget.variantName}'),
          const SizedBox(height: 8),
          Text('Current stock: ${widget.currentStock}'),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New quantity'),
          ),
          const SizedBox(height: 8),
          Text(
            diff == 0
                ? 'No change'
                : diff > 0
                    ? 'Will add $diff units (+$diff)'
                    : 'Will remove ${-diff} units ($diff)',
            style: TextStyle(
              color: diff == 0 ? null : diff > 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
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
          onPressed: diff == 0 ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final newQty = int.tryParse(_quantityController.text.trim()) ?? widget.currentStock;
    final diff = newQty - widget.currentStock;
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    await ref
        .read(inventoryRepositoryProvider)
        .createInventoryLog(
          variantId: widget.variantId,
          changeType: diff > 0 ? 'restock' : 'adjustment',
          quantityChange: diff,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdBy: userId,
        );
    if (!mounted) return;
    ref.invalidate(lowStockProvider);
    widget.onSaved?.call();
    Navigator.of(context).pop();
  }
}
