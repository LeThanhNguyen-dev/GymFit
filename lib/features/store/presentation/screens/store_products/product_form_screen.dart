import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class StoreProductFormScreen extends ConsumerStatefulWidget {
  const StoreProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<StoreProductFormScreen> createState() => _StoreProductFormScreenState();
}

class _StoreProductFormScreenState extends ConsumerState<StoreProductFormScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _hasVariants = false;
  String _selectedCategory = 'Túi xách';

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _weightCtrl.dispose(); _lengthCtrl.dispose(); _widthCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.pageHorizontal), child: _buildStep())),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Cơ bản', 'Ảnh', 'Phân loại', 'Vận chuyển', 'Xem lại'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.pageHorizontal),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: Row(children: List.generate(steps.length, (i) {
        final active = i == _step; final done = i < _step;
        return Expanded(child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.success : active ? AppColors.primary : AppColors.surfaceContainerHighest),
            child: Center(child: done ? const Icon(Icons.check, size: 14, color: Colors.black) : Text('${i + 1}', style: TextStyle(fontSize: 12, color: active ? Colors.black : AppColors.onSurfaceVariant))),
          ), const SizedBox(width: 2),
          Expanded(child: Text(steps[i], style: AppTextStyles.labelSmall.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis)),
        ]));
      })),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildBasicInfo();
      case 1: return _buildImages();
      case 2: return _buildVariants();
      case 3: return _buildShipping();
      case 4: return _buildReview();
      default: return const SizedBox();
    }
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin cơ bản', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder())),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder(), alignLabelWithHint: true)),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField(
          value: _selectedCategory, decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
          items: 'Túi xách|Phụ kiện|Quần áo|Dụng cụ'.split('|').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField(
          value: 'Nike', decoration: const InputDecoration(labelText: 'Thương hiệu', border: OutlineInputBorder()),
          items: 'Nike|Adidas|Puma|GymFit'.split('|').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ảnh sản phẩm (tối đa 8 ảnh)', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
          children: List.generate(5, (i) => Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.outlineVariant)),
            child: i == 0 ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(Icons.camera_alt, color: Colors.grey), Text('Chụp', style: TextStyle(fontSize: 10, color: Colors.grey))],
            ) : const Center(child: Icon(Icons.image, color: Colors.grey)),
          )),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Ảnh đầu tiên là ảnh đại diện', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildVariants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Sản phẩm có phân loại?'),
          value: _hasVariants,
          onChanged: (v) => setState(() => _hasVariants = v),
        ),
        if (!_hasVariants) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(decoration: const InputDecoration(labelText: 'Giá (₫)', border: OutlineInputBorder(), prefixText: '₫')),
          const SizedBox(height: AppSpacing.md),
          TextField(decoration: const InputDecoration(labelText: 'Tồn kho', border: OutlineInputBorder())),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          Chip(label: const Text('Màu sắc: Đỏ, Xanh, Đen'), onDeleted: () {}),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: const Text('Size: S, M, L'), onDeleted: () {}),
          const SizedBox(height: AppSpacing.md),
          Text('Ma trận phân loại', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          DataTable(
            columns: 'SKU|Giá|Tồn kho'.split('|').map((c) => DataColumn(label: Text(c, style: AppTextStyles.labelSmall))).toList(),
            rows: List.generate(4, (i) => DataRow(cells: [
              DataCell(Text('SP-${i + 1}')),
              DataCell(TextField(decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), style: const TextStyle(fontSize: 13))),
              DataCell(TextField(decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), style: const TextStyle(fontSize: 13))),
            ])),
          ),
        ],
      ],
    );
  }

  Widget _buildShipping() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin vận chuyển', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _weightCtrl, decoration: const InputDecoration(labelText: 'Cân nặng (gram)', border: OutlineInputBorder(), suffixText: 'g')),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: TextField(controller: _lengthCtrl, decoration: const InputDecoration(labelText: 'Dài (cm)', border: OutlineInputBorder(), suffixText: 'cm'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: TextField(controller: _widthCtrl, decoration: const InputDecoration(labelText: 'Rộng (cm)', border: OutlineInputBorder(), suffixText: 'cm'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: 'Cao (cm)', border: OutlineInputBorder(), suffixText: 'cm'))),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text('Đơn vị vận chuyển hỗ trợ', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ...'Giao hàng nhanh|Giao hàng tiết kiệm|Viettel Post'.split('|').map((c) => CheckboxListTile(value: true, onChanged: (_) {}, title: Text(c, style: AppTextStyles.bodySmall), dense: true)),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Xem lại thông tin', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 150, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: AppSpacing.sm),
                Text('Tên sản phẩm', style: AppTextStyles.titleMedium),
                Text('Danh mục: Túi xách', style: AppTextStyles.bodySmall),
                Text('Giá: 1.200.000₫ • Tồn kho: 45', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, border: Border(top: BorderSide(color: AppColors.outlineVariant))),
      child: Row(
        children: [
          if (_step > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Quay lại'))),
          if (_step > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: _step < 4 ? () => setState(() => _step++) : null,
              child: Text(_step < 4 ? 'Tiếp theo' : 'Đăng bán'),
            ),
          ),
        ],
      ),
    );
  }
}
