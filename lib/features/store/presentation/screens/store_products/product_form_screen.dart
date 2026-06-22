import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/enums/database_enums.dart';
import '../../../../products/data/models/product_model.dart';
import '../../../../products/providers/product_providers.dart';

class StoreProductFormScreen extends ConsumerStatefulWidget {
  const StoreProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<StoreProductFormScreen> createState() => _StoreProductFormScreenState();
}

class _StoreProductFormScreenState extends ConsumerState<StoreProductFormScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _basePriceCtrl = TextEditingController();
  final _compareAtPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(); // For single product mode
  final _newBrandNameCtrl = TextEditingController();
  bool _isAddingNewBrand = false;

  // Selection states
  String? _selectedCategoryId;
  String? _selectedBrandId;
  ProductStatus _selectedStatus = ProductStatus.draft;

  // Categories & Brands data
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _loadingMetadata = true;

  // Image states
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];

  // Variants state
  bool _hasVariants = false;
  final List<Map<String, dynamic>> _attributes = []; // e.g. [{'name': 'Màu sắc', 'options': ['Đỏ', 'Xanh']}]
  final List<Map<String, dynamic>> _variants = []; // Generated matrix

  void _generateVariants() {
    if (_attributes.isEmpty) {
      _variants.clear();
      return;
    }

    final oldVariants = {
      for (var v in _variants)
        if (v['optionValues'] != null)
          (v['optionValues'] as Map).entries.map((e) => '${e.key}:${e.value}').join('|'): v
    };

    List<Map<String, String>> combinations = [{}];

    for (var attr in _attributes) {
      final attrName = attr['name'] as String;
      final options = attr['options'] as List<String>;
      if (attrName.trim().isEmpty || options.isEmpty) continue;

      List<Map<String, String>> newCombinations = [];
      for (var combo in combinations) {
        for (var opt in options) {
          if (opt.trim().isEmpty) continue;
          final newCombo = Map<String, String>.from(combo);
          newCombo[attrName.trim()] = opt.trim();
          newCombinations.add(newCombo);
        }
      }
      combinations = newCombinations;
    }

    if (combinations.length == 1 && combinations.first.isEmpty) {
      _variants.clear();
      return;
    }

    _variants.clear();
    for (var combo in combinations) {
      final key = combo.entries.map((e) => '${e.key}:${e.value}').join('|');
      final oldV = oldVariants[key];
      _variants.add({
        'name': combo.values.join(' - '),
        'optionValues': combo,
        'price': oldV?['price'] ?? double.tryParse(_basePriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0,
        'quantity': oldV?['quantity'] ?? 0,
        'sku': oldV?['sku'] ?? '',
      });
    }
  }

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _basePriceCtrl.dispose();
    _compareAtPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _skuCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _stockCtrl.dispose();
    _newBrandNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final repo = ref.read(productRepositoryProvider);
    
    try {
      final catsResult = await repo.getAdminCategories();
      setState(() => _categories = catsResult.items);
    } catch (e) {
      if (kDebugMode) print('Error loading categories: $e');
    }

    try {
      final brsResult = await repo.getAdminBrands();
      setState(() => _brands = brsResult.items);
    } catch (e) {
      if (kDebugMode) print('Error loading brands: $e');
    }

    setState(() => _loadingMetadata = false);

    if (widget.productId != null) {
      _loadProductDetails();
    }
  }

  Future<void> _loadProductDetails() async {
    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProductById(widget.productId!);
      if (product != null && mounted) {
        setState(() {
          _nameCtrl.text = product.name;
          _descCtrl.text = product.description ?? '';
          _basePriceCtrl.text = product.basePrice.toStringAsFixed(0);
          _compareAtPriceCtrl.text = product.compareAtPrice?.toStringAsFixed(0) ?? '';
          _costPriceCtrl.text = product.costPrice?.toStringAsFixed(0) ?? '';
          _skuCtrl.text = product.sku ?? '';
          _weightCtrl.text = product.weightGrams?.toString() ?? '';
          _lengthCtrl.text = product.lengthCm?.toString() ?? '';
          _widthCtrl.text = product.widthCm?.toString() ?? '';
          _heightCtrl.text = product.heightCm?.toString() ?? '';
          _selectedCategoryId = product.categoryId;
          _selectedBrandId = product.brandId;
          _selectedStatus = product.status;

          _existingImageUrls.addAll(product.images.map((img) => img.url));

          if (product.variants.isNotEmpty) {
            _hasVariants = true;
            _variants.addAll(product.variants.map((v) => {
                  'id': v.id,
                  'name': v.name ?? v.optionDisplay,
                  'optionValues': v.optionValues,
                  'price': v.price,
                  'quantity': v.quantity,
                  'sku': v.sku,
                }));
            // Extract attributes from variants optionValues
            if (product.variants.first.optionValues.isNotEmpty) {
              final Map<String, Set<String>> attrMap = {};
              for (var v in product.variants) {
                for (var entry in v.optionValues.entries) {
                  attrMap.putIfAbsent(entry.key, () => {}).add(entry.value.toString());
                }
              }
              _attributes.clear();
              attrMap.forEach((key, value) {
                _attributes.add({'name': key, 'options': value.toList()});
              });
            }
          } else {
            _hasVariants = false;
            // set stock from variants if somehow stored there, or metadata
            _stockCtrl.text = '0';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải sản phẩm: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length + _existingImageUrls.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ được tải lên tối đa 8 ảnh.')));
      return;
    }
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final tempDir = await getTemporaryDirectory();
      final ext = image.name.split('.').last;
      final savedPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await image.saveTo(savedPath);
      setState(() {
        _selectedImages.add(XFile(savedPath));
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedCategoryId == null || _basePriceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ Tên, Giá, Danh mục!')));
      return;
    }

    setState(() => _isSaving = true);
    final supabase = ref.read(supabaseClientProvider);
    final repo = ref.read(productRepositoryProvider);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final name = _nameCtrl.text.trim();
      final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+$'), '');
      
      String? brandId = _selectedBrandId;
      if (_isAddingNewBrand && _newBrandNameCtrl.text.trim().isNotEmpty) {
        final newBrandName = _newBrandNameCtrl.text.trim();
        final brandSlug = newBrandName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final newBrand = await repo.saveBrand({
          'name': newBrandName,
          'slug': '$brandSlug-${DateTime.now().millisecondsSinceEpoch}',
        });
        brandId = newBrand.id;
      }

      final productData = {
        'name': name,
        'slug': '$slug-${DateTime.now().millisecondsSinceEpoch}',
        'category_id': _selectedCategoryId,
        'brand_id': brandId,
        'seller_id': userId,
        'description': _descCtrl.text.trim(),
        'base_price': double.tryParse(_basePriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0,
        'compare_at_price': double.tryParse(_compareAtPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'cost_price': double.tryParse(_costPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'sku': _skuCtrl.text.trim().isEmpty ? 'SKU-${DateTime.now().millisecondsSinceEpoch}' : _skuCtrl.text.trim(),
        'status': _selectedStatus.name,
        'weight_grams': int.tryParse(_weightCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'length_cm': double.tryParse(_lengthCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'width_cm': double.tryParse(_widthCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'height_cm': double.tryParse(_heightCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
      };

      // TODO: Save attributes to product metadata if needed.
      if (_hasVariants && _attributes.isNotEmpty) {
        productData['attributes'] = {
          for (var a in _attributes) a['name']: a['options']
        };
      }

      ProductModel savedProduct;
      if (widget.productId == null) {
        savedProduct = await repo.createProduct(productData);
      } else {
        savedProduct = await repo.updateProduct(widget.productId!, productData);
      }

      // Handle image uploads
      int sortOrder = 0;
      for (final imageFile in _selectedImages) {
        final bytes = await imageFile.readAsBytes();
        final ext = imageFile.name.split('.').last;
        final path = 'products/${savedProduct.id}/${DateTime.now().millisecondsSinceEpoch}_$sortOrder.$ext';

        await supabase.storage.from('product-images').uploadBinary(path, bytes);
        final publicUrl = supabase.storage.from('product-images').getPublicUrl(path);

        await repo.addProductImage(savedProduct.id, publicUrl, sortOrder);
        sortOrder++;
      }

      // Handle default/single variant creation if no variants enabled
      if (!_hasVariants) {
        final stock = int.tryParse(_stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final defaultVariantData = {
          'product_id': savedProduct.id,
          'sku': savedProduct.sku ?? 'SKU-${savedProduct.id.substring(0, 8)}',
          'price': savedProduct.basePrice,
          'quantity': stock,
          'stock': stock,
          'status': 'active',
        };
        
        // Check if default variant exists (for edit)
        if (widget.productId != null && savedProduct.variants.isNotEmpty) {
          await repo.updateVariant(savedProduct.variants.first.id, defaultVariantData);
        } else {
          await repo.createVariant(defaultVariantData);
        }
      } else {
        // Create custom variants
        for (int idx = 0; idx < _variants.length; idx++) {
          final v = _variants[idx];
          final variantSku = (v['sku'] == null || v['sku'].toString().trim().isEmpty)
              ? '${savedProduct.sku}-VAR-$idx'
              : v['sku'].toString().trim();
          
          final variantData = {
            'product_id': savedProduct.id,
            'sku': variantSku,
            'price': v['price'] ?? savedProduct.basePrice,
            'quantity': v['quantity'] ?? 0,
            'stock': v['quantity'] ?? 0,
            'name': v['name'] ?? '',
            'status': 'active',
          };
          if (v['id'] != null && v['id'].toString().isNotEmpty) {
            await repo.updateVariant(v['id'], variantData);
          } else {
            await repo.createVariant(variantData);
          }
        }
      }

      ref.invalidate(storeProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId != null ? 'Cập nhật thành công!' : 'Đăng bán thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu sản phẩm: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMetadata) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: Form(key: _formKey, child: _buildStep()),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Cơ bản', 'Ảnh', 'Phân loại', 'Vận chuyển', 'Xem lại'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.pageHorizontal),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.success : active ? AppColors.primary : AppColors.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : Text('${i + 1}', style: TextStyle(fontSize: 12, color: active ? Colors.black : AppColors.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    steps[i],
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
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

  String _getCategoryName(String? id) {
    if (id == null) return 'Chọn danh mục';
    try {
      final cat = _categories.firstWhere((c) => c.id == id);
      if (cat.parentId != null && cat.parentId!.isNotEmpty && cat.parentId != 'null') {
        final parent = _categories.firstWhere((c) => c.id == cat.parentId, orElse: () => cat);
        if (parent.id != cat.id) {
          return '${parent.name} > ${cat.name}';
        }
      }
      return cat.name;
    } catch (_) {
      return 'Chọn danh mục';
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        var roots = _categories.where((c) => c.parentId == null || c.parentId!.isEmpty || c.parentId == 'null').toList();
        // Nếu không có danh mục cha nào (tức là dùng danh sách phẳng), lấy tất cả làm danh mục gốc
        if (roots.isEmpty && _categories.isNotEmpty) {
          roots = List.from(_categories);
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Chọn danh mục', style: AppTextStyles.titleMedium),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: roots.length,
                    itemBuilder: (context, index) {
                      final root = roots[index];
                      final children = _categories.where((c) => c.parentId == root.id).toList();
                      if (children.isEmpty) {
                        return ListTile(
                          title: Text(root.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: _selectedCategoryId == root.id ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () {
                            setState(() => _selectedCategoryId = root.id);
                            Navigator.pop(context);
                          },
                        );
                      }
                      return ExpansionTile(
                        title: Text(root.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        initiallyExpanded: children.any((c) => c.id == _selectedCategoryId) || _selectedCategoryId == root.id,
                        children: children.map((child) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 48, right: 16),
                            title: Text(child.name),
                            trailing: _selectedCategoryId == child.id ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                            onTap: () {
                              setState(() => _selectedCategoryId = child.id);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin cơ bản', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Tên sản phẩm *', border: OutlineInputBorder()),
          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: AppSpacing.md),
        FormField<String>(
          validator: (_) => _selectedCategoryId == null ? 'Vui lòng chọn danh mục' : null,
          builder: (state) {
            return InkWell(
              onTap: _showCategoryPicker,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Danh mục *',
                  border: const OutlineInputBorder(),
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _getCategoryName(_selectedCategoryId),
                  style: TextStyle(color: _selectedCategoryId != null ? null : AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _isAddingNewBrand ? 'new' : _selectedBrandId,
          decoration: const InputDecoration(labelText: 'Thương hiệu', border: OutlineInputBorder()),
          items: [
            ..._brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
            const DropdownMenuItem(
              value: 'new',
              child: Text(
                '+ Thêm thương hiệu mới...',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          onChanged: (v) {
            if (v == 'new') {
              setState(() {
                _isAddingNewBrand = true;
                _selectedBrandId = null;
              });
            } else {
              setState(() {
                _isAddingNewBrand = false;
                _selectedBrandId = v;
              });
            }
          },
        ),
        if (_isAddingNewBrand) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _newBrandNameCtrl,
            decoration: InputDecoration(
              labelText: 'Tên thương hiệu mới *',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () => setState(() {
                  _isAddingNewBrand = false;
                  _newBrandNameCtrl.clear();
                }),
              ),
            ),
            validator: (v) => _isAddingNewBrand && (v == null || v.isEmpty) ? 'Vui lòng nhập tên thương hiệu mới' : null,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ProductStatus>(
          initialValue: _selectedStatus,
          decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: ProductStatus.active, child: Text('Đang bán (Active)')),
            DropdownMenuItem(value: ProductStatus.inactive, child: Text('Ẩn (Inactive)')),
            DropdownMenuItem(value: ProductStatus.draft, child: Text('Nháp (Draft)')),
          ],
          onChanged: (v) => setState(() => _selectedStatus = v!),
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
          children: [
            // List of existing images
            ..._existingImageUrls.map((url) => Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 0, top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _existingImageUrls.remove(url)),
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                )),
            // List of picked images
            ..._selectedImages.map((file) => Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                        image: DecorationImage(
                          image: kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0, top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.remove(file)),
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                )),
            if (_selectedImages.length + _existingImageUrls.length < 8)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey),
                      Text('Thêm ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Phân loại hàng', style: AppTextStyles.titleMedium),
            Switch(
              value: _hasVariants,
              onChanged: (val) {
                setState(() {
                  _hasVariants = val;
                  if (!val) {
                    _attributes.clear();
                    _variants.clear();
                  } else if (_attributes.isEmpty) {
                    _attributes.add({'name': 'Màu sắc', 'options': <String>[]});
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _basePriceCtrl,
          decoration: const InputDecoration(labelText: 'Giá cơ bản (₫) *', border: OutlineInputBorder(), prefixText: '₫ '),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập giá bán' : null,
          onChanged: (_) => setState(() => _generateVariants()),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _compareAtPriceCtrl,
                decoration: const InputDecoration(labelText: 'Giá so sánh', border: OutlineInputBorder(), prefixText: '₫ '),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _costPriceCtrl,
                decoration: const InputDecoration(labelText: 'Giá vốn', border: OutlineInputBorder(), prefixText: '₫ '),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _skuCtrl,
          decoration: const InputDecoration(labelText: 'Mã sản phẩm (SKU)', border: OutlineInputBorder()),
        ),
        if (!_hasVariants) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _stockCtrl,
            decoration: const InputDecoration(labelText: 'Số lượng tồn kho', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Nhóm phân loại', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attributes.length,
            itemBuilder: (context, attrIndex) {
              final attr = _attributes[attrIndex];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: attr['name'],
                              decoration: const InputDecoration(labelText: 'Tên nhóm (VD: Màu sắc, Kích cỡ)', border: OutlineInputBorder(), isDense: true),
                              onChanged: (val) {
                                _attributes[attrIndex]['name'] = val;
                                _generateVariants();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error),
                            onPressed: () => setState(() {
                              _attributes.removeAt(attrIndex);
                              _generateVariants();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...(attr['options'] as List<String>).asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              onDeleted: () {
                                setState(() {
                                  (attr['options'] as List<String>).removeAt(entry.key);
                                  _generateVariants();
                                });
                              },
                            );
                          }),
                          ActionChip(
                            label: const Text('+ Thêm tuỳ chọn', style: TextStyle(color: AppColors.primary)),
                            backgroundColor: AppColors.primaryContainer,
                            onPressed: () {
                              _showAddOptionDialog(attrIndex);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _showAddOptionDialog(int attrIndex) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tuỳ chọn'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nhập tuỳ chọn (Đỏ, Size L,...)'),
          autofocus: true,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                (_attributes[attrIndex]['options'] as List<String>).add(val.trim());
                _generateVariants();
              });
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  (_attributes[attrIndex]['options'] as List<String>).add(ctrl.text.trim());
                  _generateVariants();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildShipping() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin vận chuyển', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _weightCtrl,
          decoration: const InputDecoration(labelText: 'Cân nặng (gram)', border: OutlineInputBorder(), suffixText: 'g'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lengthCtrl,
                decoration: const InputDecoration(labelText: 'Dài (cm)', border: OutlineInputBorder(), suffixText: 'cm'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _widthCtrl,
                decoration: const InputDecoration(labelText: 'Rộng (cm)', border: OutlineInputBorder(), suffixText: 'cm'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _heightCtrl,
                decoration: const InputDecoration(labelText: 'Cao (cm)', border: OutlineInputBorder(), suffixText: 'cm'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
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
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: kIsWeb ? NetworkImage(_selectedImages.first.path) : FileImage(File(_selectedImages.first.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (_existingImageUrls.isNotEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_existingImageUrls.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Icon(Icons.image, size: 40, color: AppColors.onSurfaceVariant)),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(_nameCtrl.text, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text('Giá cơ bản: ${_basePriceCtrl.text}₫', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Trạng thái lưu: ${_selectedStatus.name.toUpperCase()}', style: AppTextStyles.bodySmall),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Quay lại'))),
          if (_step > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving
                  ? null
                  : _step < 4
                      ? () {
                          if (_step == 0 && !_formKey.currentState!.validate()) return;
                          setState(() => _step++);
                        }
                      : _saveProduct,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_step < 4 ? 'Tiếp theo' : (widget.productId != null ? 'Cập nhật' : 'Đăng bán')),
            ),
          ),
        ],
      ),
    );
  }
}
