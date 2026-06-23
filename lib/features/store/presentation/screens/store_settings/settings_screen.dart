import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/supabase_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../auth/providers/auth_providers.dart';
import '../../../../register_shop/providers/shop_registration_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _initFields(dynamic reg) {
    if (_initialized || reg == null) return;
    _nameCtrl.text = reg.shopName;
    _descCtrl.text = reg.shopDescription ?? '';
    _phoneCtrl.text = reg.phoneNumber;
    _addressCtrl.text = reg.address;
    _initialized = true;
  }

  Future<void> _saveShopInfo(dynamic reg) async {
    if (reg == null) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(shopRegistrationRepositoryProvider);
      await repo.updateRegistration(
        id: reg.id,
        userId: reg.userId,
        shopName: _nameCtrl.text.trim(),
        shopDescription: _descCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        fullName: reg.fullName,
        cccdNumber: reg.cccdNumber,
        dateOfBirth: reg.dateOfBirth,
        issuedDate: reg.issuedDate,
        issuedPlace: reg.issuedPlace,
        businessType: reg.businessType,
        existingCccdFrontUrl: reg.cccdFrontUrl,
        existingCccdBackUrl: reg.cccdBackUrl,
        existingBusinessLicenseUrl: reg.businessLicenseUrl,
        taxCode: reg.taxCode,
      );
      ref.invalidate(myShopRegistrationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thông tin Shop thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnsupported(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature chưa được hỗ trợ trong bản này.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regAsyncValue = ref.watch(myShopRegistrationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt Shop'), elevation: 0),
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabs: 'Thông tin Shop|Cài đặt|Đánh giá'.split('|').map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: regAsyncValue.when(
              data: (reg) {
                if (reg != null) {
                  _initFields(reg);
                }
                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildShopInfo(reg),
                    _buildSettings(),
                    _buildReviews(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo(dynamic reg) {
    if (reg == null) {
      return const Center(child: Text('Không tìm thấy thông tin đăng ký Shop.'));
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Center(
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(Icons.store, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(reg.businessTypeDisplay, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Tên shop', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: 'Mô tả shop', border: OutlineInputBorder(), alignLabelWithHint: true),
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _isLoading ? null : () => _saveShopInfo(reg),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu thông tin'),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Chính sách đổi trả', style: AppTextStyles.bodyMedium),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUnsupported('Chính sách đổi trả'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Giờ hoạt động', style: AppTextStyles.bodyMedium),
                subtitle: Text('T2-CN: 08:00 - 22:00', style: AppTextStyles.bodySmall),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUnsupported('Giờ hoạt động'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildShopVouchers(),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: Text('Đơn hàng mới', style: AppTextStyles.bodyMedium),
                value: true,
                onChanged: (_) => _showUnsupported('Thông báo đơn hàng mới'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.inventory),
                title: Text('Cảnh báo hết hàng', style: AppTextStyles.bodyMedium),
                value: true,
                onChanged: (_) => _showUnsupported('Cảnh báo hết hàng'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.rate_review),
                title: Text('Đánh giá mới', style: AppTextStyles.bodyMedium),
                value: false,
                onChanged: (_) => _showUnsupported('Thông báo đánh giá mới'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout().then((_) {
                context.go('/login');
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopVouchers() {
    final supabase = ref.watch(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Voucher của shop', style: AppTextStyles.titleMedium),
                ),
                TextButton.icon(
                  onPressed: userId == null
                      ? null
                      : () => _showShopVoucherDialog(userId: userId),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<dynamic>>(
              future: userId == null
                  ? Future.value([])
                  : supabase
                        .from('vouchers')
                        .select()
                        .eq('scope', 'shop')
                        .eq('seller_id', userId)
                        .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Không thể tải voucher shop: ${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  );
                }

                final vouchers = snapshot.data ?? const [];
                if (vouchers.isEmpty) {
                  return Text(
                    'Chưa có voucher riêng cho shop.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }

                return Column(
                  children: vouchers.map((raw) {
                    final voucher = Map<String, dynamic>.from(raw as Map);
                    final active = voucher['is_active'] as bool? ?? true;
                    final code = voucher['code']?.toString() ?? '';
                    final discountType = voucher['discount_type']?.toString();
                    final value = voucher['discount_value']?.toString() ?? '0';
                    final display = discountType == 'percentage'
                        ? '$value%'
                        : '${double.tryParse(value)?.toStringAsFixed(0) ?? value}đ';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.local_offer_outlined,
                        color: active ? AppColors.primary : AppColors.outline,
                      ),
                      title: Text(code),
                      subtitle: Text('Giảm $display'),
                      trailing: Switch(
                        value: active,
                        onChanged: (next) async {
                          await supabase
                              .from('vouchers')
                              .update({
                                'is_active': next,
                                'updated_at': DateTime.now().toIso8601String(),
                              })
                              .eq('id', voucher['id']);
                          if (mounted) setState(() {});
                        },
                      ),
                      onTap: () => _showShopVoucherDialog(
                        userId: userId!,
                        voucher: voucher,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showShopVoucherDialog({
    required String userId,
    Map<String, dynamic>? voucher,
  }) async {
    final codeCtrl = TextEditingController(text: voucher?['code']?.toString());
    final valueCtrl = TextEditingController(
      text: voucher?['discount_value']?.toString() ?? '0',
    );
    final minCtrl = TextEditingController(
      text: voucher?['min_order_amount']?.toString() ?? '0',
    );
    final limitCtrl = TextEditingController(
      text: voucher?['usage_limit']?.toString() ?? '',
    );
    var discountType = voucher?['discount_type']?.toString() ?? 'fixed';
    var active = voucher?['is_active'] as bool? ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(voucher == null ? 'Thêm voucher shop' : 'Sửa voucher shop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mã voucher'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Giảm tiền')),
                    DropdownMenuItem(value: 'percentage', child: Text('Giảm %')),
                  ],
                  onChanged: (value) =>
                      setLocalState(() => discountType = value ?? discountType),
                ),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá trị giảm'),
                ),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn tối thiểu'),
                ),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lượt dùng tối đa'),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setLocalState(() => active = value),
                  title: const Text('Đang hoạt động'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeCtrl.text.trim().toUpperCase();
                if (code.isEmpty) return;
                final payload = {
                  'code': code,
                  'description': 'Shop voucher',
                  'scope': 'shop',
                  'seller_id': userId,
                  'discount_type': discountType,
                  'discount_value': double.tryParse(valueCtrl.text.trim()) ?? 0,
                  'min_order_amount': double.tryParse(minCtrl.text.trim()) ?? 0,
                  'usage_limit': int.tryParse(limitCtrl.text.trim()),
                  'is_active': active,
                  'start_date': DateTime.now().toIso8601String(),
                  'end_date': DateTime.now()
                      .add(const Duration(days: 30))
                      .toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                };
                final supabase = ref.read(supabaseClientProvider);
                if (voucher == null) {
                  await supabase.from('vouchers').insert(payload);
                } else {
                  await supabase
                      .from('vouchers')
                      .update(payload)
                      .eq('id', voucher['id']);
                }
                if (mounted) setState(() {});
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviews() {
    // We can fetch reviews using a simple future builder
    final supabase = ref.watch(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    return FutureBuilder<List<dynamic>>(
      future: userId == null
          ? Future.value([])
          : supabase
              .from('reviews')
              .select('*, profiles(full_name), products!inner(name, seller_id)')
              .eq('products.seller_id', userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(child: Text('Chưa có đánh giá nào cho sản phẩm của bạn.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final review = reviews[i];
            final profile = review['profiles'] as Map<String, dynamic>?;
            final product = review['products'] as Map<String, dynamic>?;
            final rating = review['rating'] as int? ?? 5;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        child: Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Text(profile?['full_name']?.toString() ?? 'Ẩn danh', style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (s) => Icon(
                            Icons.star,
                            size: 16,
                            color: s < rating ? AppColors.warning : AppColors.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      product?['name']?.toString() ?? 'Sản phẩm',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(review['content']?.toString() ?? '', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
