import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../voucher/data/models/voucher_model.dart';
import '../../voucher/providers/voucher_provider.dart';

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  final _searchController = TextEditingController();
  bool? _isActive;
  String? _discountType;
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
    final repository = ref.watch(voucherRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage vouchers')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminVouchers(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                isActive: _isActive,
                discountType: _discountType,
                sortBy: _sortBy,
                ascending: _ascending,
                page: _page,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data!;
                final vouchers = result.items;
                if (vouchers.isEmpty) {
                  return const Center(child: Text('No vouchers.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    itemCount: vouchers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final voucher = vouchers[index];
                      return ListTile(
                        title: Text(voucher.code),
                        subtitle: Text(
                          '${voucher.discountDisplay} - used ${voucher.usedCount}',
                        ),
                        trailing: Switch(
                          value: voucher.isActive,
                          onChanged: (value) async {
                            await repository.saveVoucher({
                              'is_active': value,
                            }, id: voucher.id);
                            if (mounted) setState(() {});
                          },
                        ),
                        onTap: () => _showVoucherDialog(voucher),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVoucherDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search by code',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('All', null, _isActive),
            const SizedBox(width: 8),
            _buildChip('Active', true, _isActive),
            const SizedBox(width: 8),
            _buildChip('Inactive', false, _isActive),
            const SizedBox(width: 16),
            _buildChip('All type', null, _discountType),
            const SizedBox(width: 8),
            _buildChip('Percentage', 'percentage', _discountType),
            const SizedBox(width: 8),
            _buildChip('Fixed', 'fixed_amount', _discountType),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Object? value, Object? currentValue) {
    final selected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (value is bool? || value is bool) {
            _isActive = selected ? null : (value as bool?);
          } else if (value is String?) {
            _discountType = selected ? null : (value as String?);
          } else {
            _isActive = null;
            _discountType = null;
          }
          _page = 1;
        });
      },
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Mới nhất'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('discount_value', 'Value low-high'),
      SortOption('discount_value_desc', 'Value high-low'),
      SortOption('start_date', 'Start date'),
      SortOption('start_date_desc', 'Start date desc'),
      SortOption('end_date', 'End date'),
      SortOption('end_date_desc', 'End date desc'),
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
      future: ref.read(voucherRepositoryProvider).getAdminVouchers(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        isActive: _isActive,
        discountType: _discountType,
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

  Future<void> _showVoucherDialog(VoucherModel? voucher) async {
    final code = TextEditingController(text: voucher?.code);
    final description = TextEditingController(text: voucher?.description);
    final value = TextEditingController(
      text: voucher?.discountValue.toString() ?? '0',
    );
    final minOrder = TextEditingController(
      text: voucher?.minOrderAmount.toString() ?? '0',
    );
    final usageLimit = TextEditingController(
      text: voucher?.usageLimit?.toString(),
    );
    var discountType = voucher?.discountType ?? 'percentage';
    var active = voucher?.isActive ?? true;
    var startDate = voucher?.startDate ?? DateTime.now();
    var endDate =
        voucher?.endDate ?? DateTime.now().add(const Duration(days: 30));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(voucher == null ? 'Add voucher' : 'Edit voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed_amount',
                      child: Text('Fixed amount'),
                    ),
                  ],
                  onChanged: (next) =>
                      setLocalState(() => discountType = next ?? discountType),
                ),
                TextField(
                  controller: value,
                  decoration: const InputDecoration(
                    labelText: 'Discount value',
                  ),
                ),
                TextField(
                  controller: minOrder,
                  decoration: const InputDecoration(labelText: 'Min order'),
                ),
                TextField(
                  controller: usageLimit,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit optional',
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (next) => setLocalState(() => active = next),
                  title: const Text('Active'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: startDate,
                    );
                    if (picked != null) {
                      setLocalState(() => startDate = picked);
                    }
                  },
                  child: Text(
                    'Start: ${startDate.toIso8601String().split('T').first}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: endDate,
                    );
                    if (picked != null) {
                      setLocalState(() => endDate = picked);
                    }
                  },
                  child: Text(
                    'End: ${endDate.toIso8601String().split('T').first}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(voucherRepositoryProvider).saveVoucher({
                  'code': code.text.trim().toUpperCase(),
                  'description': description.text.trim(),
                  'discount_type': discountType,
                  'discount_value': double.tryParse(value.text.trim()) ?? 0,
                  'min_order_amount':
                      double.tryParse(minOrder.text.trim()) ?? 0,
                  'usage_limit': int.tryParse(usageLimit.text.trim()),
                  'is_active': active,
                  'start_date': startDate.toIso8601String(),
                  'end_date': endDate.toIso8601String(),
                }, id: voucher?.id);
                if (mounted) setState(() {});
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
