import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../voucher/data/models/voucher_model.dart';
import '../../voucher/providers/voucher_provider.dart';
import '../../voucher/data/repositories/voucher_repository.dart';

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
  static const int _pageSize = 10;

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
    final theme = Theme.of(context);
    final repository = ref.watch(voucherRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([
          repository.getAdminVouchers(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            isActive: _isActive,
            discountType: _discountType,
            sortBy: _sortBy,
            ascending: _ascending,
            page: _page,
            pageSize: _pageSize,
          ),
          repository.getVoucherStats(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải dữ liệu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vouchersResult = snapshot.data![0] as ({List<VoucherModel> items, int totalCount});
          final statsResult = snapshot.data![1] as Map<String, int>;

          final vouchers = vouchersResult.items;
          final totalCount = vouchersResult.totalCount;
          final totalPages = (totalCount / _pageSize).ceil();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Statistics Row
              _buildStatsGrid(statsResult),
              
              // Filter Actions Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 8),
                      _buildFilterRow(),
                      const SizedBox(height: 8),
                      _buildSortRow(),
                    ],
                  ),
                ),
              ),

              // Vouchers List
              Expanded(
                child: vouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sell_outlined, size: 64, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy voucher nào.',
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: vouchers.length,
                          itemBuilder: (context, index) {
                            return _buildVoucherCard(vouchers[index], repository);
                          },
                        ),
                      ),
              ),

              // Pagination
              PaginationBar(
                page: _page,
                totalPages: totalPages,
                totalItems: totalCount,
                onPageChanged: (p) => setState(() => _page = p),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Voucher'),
      ),
    );
  }

  Widget _buildMiniStatsCard({
    required String title,
    required String value,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _buildMiniStatsCard(
                title: 'Tổng',
                value: '${stats['total'] ?? 0}',
                color: Theme.of(context).colorScheme.primary,
                context: context,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildMiniStatsCard(
                title: 'Đang chạy',
                value: '${stats['active'] ?? 0}',
                color: Colors.green,
                context: context,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildMiniStatsCard(
                title: 'Vô hiệu',
                value: '${stats['inactive'] ?? 0}',
                color: Colors.orange,
                context: context,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildStatsCard(
              title: 'Tổng Voucher',
              value: '${stats['total'] ?? 0}',
              icon: Icons.sell,
              color: Theme.of(context).colorScheme.primary,
              context: context,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatsCard(
              title: 'Đang hoạt động',
              value: '${stats['active'] ?? 0}',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              context: context,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatsCard(
              title: 'Vô hiệu hóa / Hết hạn',
              value: '${stats['inactive'] ?? 0}',
              icon: Icons.history,
              color: Colors.orange,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        labelText: 'Tìm kiếm theo mã voucher...',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onFilterChanged();
                },
              )
            : null,
      ),
      onChanged: (_) => _onFilterChanged(),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<bool?>(
            value: _isActive,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: true, child: Text('Đang hoạt động')),
              DropdownMenuItem(value: false, child: Text('Đã vô hiệu hóa')),
            ],
            onChanged: (val) {
              setState(() {
                _isActive = val;
                _page = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: _discountType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Loại giảm giá',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả các loại')),
              DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
              DropdownMenuItem(value: 'fixed', child: Text('Cố định (đ)')),
            ],
            onChanged: (val) {
              setState(() {
                _discountType = val;
                _page = 1;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Ngày tạo (Mới nhất)'),
      SortOption('created_at', 'Ngày tạo (Cũ nhất)'),
      SortOption('discount_value_desc', 'Trị giá giảm (Cao -> Thấp)'),
      SortOption('discount_value', 'Trị giá giảm (Thấp -> Cao)'),
      SortOption('start_date_desc', 'Bắt đầu (Mới nhất)'),
      SortOption('start_date', 'Bắt đầu (Cũ nhất)'),
      SortOption('end_date_desc', 'Kết thúc (Mới nhất)'),
      SortOption('end_date', 'Kết thúc (Cũ nhất)'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return SortDropdown(
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
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher, VoucherRepository repository) {
    final theme = Theme.of(context);
    final isPercentage = voucher.discountType == 'percentage';

    final usageLimit = voucher.usageLimit;
    final usedCount = voucher.usedCount;
    final hasLimit = usageLimit != null;
    final limitPercent = hasLimit ? (usedCount / usageLimit).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final isExpired = voucher.endDate.isBefore(now);
    final isUpcoming = voucher.startDate.isAfter(now);

    Color statusColor = Colors.grey;
    String statusText = 'Vô hiệu';
    if (voucher.isActive) {
      if (isExpired) {
        statusColor = Colors.red;
        statusText = 'Hết hạn';
      } else if (isUpcoming) {
        statusColor = Colors.blue;
        statusText = 'Sắp diễn ra';
      } else {
        statusColor = Colors.green;
        statusText = 'Đang chạy';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: voucher.isActive && !isExpired && !isUpcoming
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showVoucherDialog(voucher),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (voucher.isActive && !isExpired)
                          ? theme.colorScheme.primaryContainer
                          : theme.disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isPercentage ? Icons.percent : Icons.wallet,
                      color: (voucher.isActive && !isExpired)
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.disabledColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              voucher.code,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: (voucher.isActive && !isExpired) ? null : Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (voucher.description != null && voucher.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            voucher.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniInfo('Giảm giá', voucher.discountDisplay, theme),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMiniInfo(
                      'Đơn tối thiểu',
                      voucher.minOrderAmount > 0 ? '${voucher.minOrderAmount.toInt()}đ' : '0đ',
                      theme,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMiniInfo(
                      'Giảm tối đa',
                      voucher.maxDiscountAmount != null ? '${voucher.maxDiscountAmount!.toInt()}đ' : 'Không giới hạn',
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasLimit) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Đã sử dụng: $usedCount / $usageLimit lượt',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(limitPercent * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: limitPercent,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      limitPercent > 0.85 ? Colors.orange : theme.colorScheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  'Đã sử dụng: $usedCount lượt (Không giới hạn)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      Text(
                        '${_formatDate(voucher.startDate)} - ${_formatDate(voucher.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (voucher.isActive) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () => _showVoucherDialog(voucher),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          tooltip: 'Vô hiệu hóa (Xóa mềm)',
                          onPressed: () => _confirmDelete(voucher, repository),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.restore, size: 20, color: Colors.green),
                          tooltip: 'Khôi phục',
                          onPressed: () async {
                            try {
                              await repository.restoreVoucher(voucher.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã khôi phục hoạt động voucher ${voucher.code}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                setState(() {});
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _confirmDelete(VoucherModel voucher, VoucherRepository repository) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Vô hiệu hóa voucher?'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa (xóa mềm) voucher "${voucher.code}" không? Khách hàng sẽ không thể sử dụng mã này nữa cho đến khi được khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await repository.deleteVoucher(voucher.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã vô hiệu hóa voucher ${voucher.code}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa voucher: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showVoucherDialog(VoucherModel? voucher) async {
    final formKey = GlobalKey<FormState>();
    final code = TextEditingController(text: voucher?.code);
    final description = TextEditingController(text: voucher?.description);
    
    final discountVal = voucher?.discountValue;
    final value = TextEditingController(
      text: discountVal != null
          ? (discountVal % 1 == 0
              ? discountVal.toInt().toString()
              : discountVal.toString())
          : '0',
    );
    
    final minOrderVal = voucher?.minOrderAmount;
    final minOrder = TextEditingController(
      text: minOrderVal != null
          ? (minOrderVal % 1 == 0
              ? minOrderVal.toInt().toString()
              : minOrderVal.toString())
          : '0',
    );
    
    final maxDiscountVal = voucher?.maxDiscountAmount;
    final maxDiscount = TextEditingController(
      text: maxDiscountVal != null
          ? (maxDiscountVal % 1 == 0
              ? maxDiscountVal.toInt().toString()
              : maxDiscountVal.toString())
          : '',
    );
    final usageLimit = TextEditingController(
      text: voucher?.usageLimit?.toString() ?? '',
    );

    var discountType = voucher?.discountType ?? 'percentage';
    if (discountType == 'fixed_amount') {
      discountType = 'fixed';
    }

    var active = voucher?.isActive ?? true;
    var startDate = voucher?.startDate ?? DateTime.now();
    var endDate = voucher?.endDate ?? DateTime.now().add(const Duration(days: 30));

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              voucher == null ? Icons.add_circle_outline : Icons.edit_note,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(voucher == null ? 'Thêm Voucher Mới' : 'Cập Nhật Voucher'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: code,
                    decoration: const InputDecoration(
                      labelText: 'Mã giảm giá (Ví dụ: GYMFIT50)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.code),
                      helperText: 'Chỉ chứa chữ in hoa, số và gạch ngang',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Mã giảm giá bắt buộc nhập';
                      if (val.trim().length < 3) return 'Mã phải dài từ 3 ký tự trở lên';
                      final regex = RegExp(r'^[A-Z0-9_-]+$');
                      if (!regex.hasMatch(val.trim().toUpperCase())) {
                        return 'Chỉ chứa chữ in hoa, số và gạch ngang';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (stateCtx, setTypeState) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: discountType,
                            decoration: const InputDecoration(
                              labelText: 'Loại giảm giá',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_offer_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Phần trăm (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Số tiền cố định (đ)'),
                              ),
                            ],
                            onChanged: (next) {
                              if (next != null) {
                                setTypeState(() => discountType = next);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: value,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: discountType == 'percentage'
                                  ? 'Giá trị giảm (%)'
                                  : 'Giá trị giảm (đ)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.monetization_on_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Bắt buộc nhập giá trị giảm';
                              final numVal = double.tryParse(val.trim());
                              if (numVal == null || numVal <= 0) return 'Giá trị giảm phải lớn hơn 0';
                              if (discountType == 'percentage' && numVal > 100) {
                                return 'Tỷ lệ giảm tối đa là 100%';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minOrder,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Đơn tối thiểu (đ)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Bắt buộc nhập';
                            final numVal = double.tryParse(val.trim());
                            if (numVal == null || numVal < 0) return 'Phải từ 0đ';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: maxDiscount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giảm tối đa (đ)',
                            border: OutlineInputBorder(),
                            helperText: 'Để trống nếu không giới hạn',
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              final numVal = double.tryParse(val.trim());
                              if (numVal == null || numVal < 0) return 'Giá trị không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usageLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giới hạn số lần sử dụng (Lượt)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people_outline),
                      helperText: 'Để trống nếu không giới hạn',
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final numVal = int.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) return 'Số lần sử dụng phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (dateCtx, setDateState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thời gian áp dụng:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: startDate,
                                    );
                                    if (picked != null) {
                                      setDateState(() => startDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            0,
                                            0,
                                            0,
                                          ));
                                    }
                                  },
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: Text(
                                    'Bắt đầu:\n${_formatDate(startDate)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: endDate,
                                    );
                                    if (picked != null) {
                                      setDateState(() => endDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            23,
                                            59,
                                            59,
                                          ));
                                    }
                                  },
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: Text(
                                    'Kết thúc:\n${_formatDate(endDate)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (switchCtx, setSwitchState) {
                      return SwitchListTile(
                        value: active,
                        onChanged: (val) => setSwitchState(() => active = val),
                        title: const Text('Kích hoạt ngay'),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;

              if (endDate.isBefore(startDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ngày kết thúc phải sau ngày bắt đầu'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final payload = {
                'code': code.text.trim().toUpperCase(),
                'description': description.text.trim(),
                'scope': 'admin',
                'seller_id': null,
                'discount_type': discountType,
                'discount_value': double.parse(value.text.trim()),
                'min_order_amount': double.parse(minOrder.text.trim()),
                'max_discount_amount': maxDiscount.text.trim().isNotEmpty
                    ? double.parse(maxDiscount.text.trim())
                    : null,
                'usage_limit': usageLimit.text.trim().isNotEmpty
                    ? int.parse(usageLimit.text.trim())
                    : null,
                'is_active': active,
                'start_date': startDate.toIso8601String(),
                'end_date': endDate.toIso8601String(),
              };

              try {
                await ref.read(voucherRepositoryProvider).saveVoucher(
                      payload,
                      id: voucher?.id,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(voucher == null
                          ? 'Đã tạo thành công voucher mới'
                          : 'Đã cập nhật thành công voucher'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {});
                }
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi lưu voucher: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu lại'),
          ),
        ],
      ),
    );
  }
}
