import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../address/data/models/address_model.dart';
import '../../../address/providers/address_providers.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ của tôi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa chỉ'),
      ),
      body: addressesAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(userAddressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.location_on_outlined,
              message: 'Chưa có địa chỉ nào\nThêm địa chỉ giao hàng ngay',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80,
            ),
            itemCount: addresses.length,
            itemBuilder: (_, index) => _AddressCard(
              address: addresses[index],
              onEdit: () => _showAddressForm(context, ref, addresses[index]),
              onDelete: () => _deleteAddress(context, ref, addresses[index]),
              onSetDefault: addresses[index].isDefault
                  ? null
                  : () => _setDefault(context, ref, addresses[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddressForm(
    BuildContext context,
    WidgetRef ref,
    AddressModel? existing,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AddressFormSheet(
        existingAddress: existing,
        onSave: (address) async {
          Navigator.of(sheetContext).pop();
          final repo = ref.read(addressRepositoryProvider);
          try {
            if (existing != null) {
              await repo.updateAddress(address);
            } else {
              await repo.createAddress(address);
            }
            ref.invalidate(userAddressesProvider);
            if (context.mounted) {
              showAppSnackbar(context,
                  message: existing != null
                      ? 'Cập nhật địa chỉ thành công'
                      : 'Thêm địa chỉ thành công',
                  type: SnackbarType.success);
            }
          } catch (e) {
            if (context.mounted) {
              showAppSnackbar(context,
                  message: 'Lỗi: ${e.toString().replaceFirst("Exception: ", "")}',
                  type: SnackbarType.error);
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Xóa địa chỉ',
      message: 'Bạn có chắc muốn xóa địa chỉ này?',
      confirmText: 'Xóa',
      confirmColor: AppColors.error,
    );
    if (confirmed == true) {
      try {
        final repo = ref.read(addressRepositoryProvider);
        await repo.deleteAddress(address.id);
        ref.invalidate(userAddressesProvider);
        if (context.mounted) {
          showAppSnackbar(context,
              message: 'Đã xóa địa chỉ', type: SnackbarType.success);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackbar(context,
              message: 'Lỗi: ${e.toString().replaceFirst("Exception: ", "")}',
              type: SnackbarType.error);
        }
      }
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) async {
    try {
      final repo = ref.read(addressRepositoryProvider);
      await repo.setDefaultAddress(address.id);
      ref.invalidate(userAddressesProvider);
      if (context.mounted) {
        showAppSnackbar(context,
            message: 'Đã đặt làm mặc định', type: SnackbarType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar(context,
            message: 'Lỗi: ${e.toString().replaceFirst("Exception: ", "")}',
            type: SnackbarType.error);
      }
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  final AddressModel address;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Mặc định',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'Sửa',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
                tooltip: 'Xóa',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.fullName ?? '',
            style: AppTextStyles.titleSmall,
          ),
          if (address.phone != null && address.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(address.phone!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            address.fullAddress,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (onSetDefault != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSetDefault,
                child: const Text('Đặt làm mặc định'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({
    this.existingAddress,
    required this.onSave,
  });

  final AddressModel? existingAddress;
  final void Function(AddressModel) onSave;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _address1Ctl = TextEditingController();
  final _address2Ctl = TextEditingController();
  final _wardCtl = TextEditingController();
  final _districtCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAddress;
    if (a != null) {
      _nameCtl.text = a.fullName ?? '';
      _phoneCtl.text = a.phone ?? '';
      _address1Ctl.text = a.addressLine1;
      _address2Ctl.text = a.addressLine2 ?? '';
      _wardCtl.text = a.ward ?? '';
      _districtCtl.text = a.district ?? '';
      _cityCtl.text = a.city;
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _address1Ctl.dispose();
    _address2Ctl.dispose();
    _wardCtl.dispose();
    _districtCtl.dispose();
    _cityCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final address = AddressModel(
      id: widget.existingAddress?.id ?? '',
      userId: widget.existingAddress?.userId ?? userId,
      fullName: _nameCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      addressLine1: _address1Ctl.text.trim(),
      addressLine2: _address2Ctl.text.trim().isEmpty ? null : _address2Ctl.text.trim(),
      ward: _wardCtl.text.trim().isEmpty ? null : _wardCtl.text.trim(),
      district: _districtCtl.text.trim().isEmpty ? null : _districtCtl.text.trim(),
      city: _cityCtl.text.trim(),
      isDefault: _isDefault,
    );

    widget.onSave(address);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingAddress != null
                    ? 'Sửa địa chỉ'
                    : 'Thêm địa chỉ mới',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Họ và tên',
                      hintText: 'Người nhận',
                      controller: _nameCtl,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Số điện thoại',
                      hintText: 'SĐT người nhận',
                      controller: _phoneCtl,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập SĐT' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Địa chỉ',
                hintText: 'Số nhà, tên đường',
                controller: _address1Ctl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Địa chỉ (bổ sung)',
                hintText: 'Tòa nhà, số tầng, ...',
                controller: _address2Ctl,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Phường/Xã',
                      hintText: 'Phường/Xã',
                      controller: _wardCtl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Quận/Huyện',
                      hintText: 'Quận/Huyện',
                      controller: _districtCtl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Thành phố',
                hintText: 'Thành phố',
                controller: _cityCtl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập thành phố' : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                title: const Text('Đặt làm địa chỉ mặc định'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                label: widget.existingAddress != null
                    ? 'Cập nhật'
                    : 'Thêm địa chỉ',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
