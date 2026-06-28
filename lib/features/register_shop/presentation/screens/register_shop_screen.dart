import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/models/shop_registration_model.dart';
import '../../providers/shop_registration_providers.dart';

class RegisterShopScreen extends ConsumerStatefulWidget {
  const RegisterShopScreen({super.key, this.existingRegistration});

  final ShopRegistrationModel? existingRegistration;

  @override
  ConsumerState<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends ConsumerState<RegisterShopScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  final _shopNameCtrl = TextEditingController();
  final _shopDescCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  XFile? _cccdFrontFile;
  XFile? _cccdBackFile;
  final _fullNameCtrl = TextEditingController();
  final _cccdNumberCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime? _issuedDate;
  final _issuedPlaceCtrl = TextEditingController();

  XFile? _bizLicenseFile;
  final _taxCodeCtrl = TextEditingController();
  String _businessType = 'individual';

  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRegistration;
    if (existing != null) {
      _shopNameCtrl.text = existing.shopName;
      _shopDescCtrl.text = existing.shopDescription ?? '';
      _phoneCtrl.text = existing.phoneNumber;
      _addressCtrl.text = existing.address;
      _fullNameCtrl.text = existing.fullName;
      _cccdNumberCtrl.text = existing.cccdNumber;
      _dateOfBirth = existing.dateOfBirth;
      _issuedDate = existing.issuedDate;
      _issuedPlaceCtrl.text = existing.issuedPlace;
      _taxCodeCtrl.text = existing.taxCode ?? '';
      _businessType = existing.businessType.name;
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopDescCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fullNameCtrl.dispose();
    _cccdNumberCtrl.dispose();
    _issuedPlaceCtrl.dispose();
    _taxCodeCtrl.dispose();
    super.dispose();
  }



  Future<void> _pickImage(XFile? target, Function(XFile?) setter) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setter(result);
    }
  }

  void _handleNext() {
    if (_currentStep < 3) {
      final formValid = switch (_currentStep) {
        0 => _formKey1.currentState?.validate() ?? false,
        1 => _formKey2.currentState?.validate() ?? false,
        2 => _formKey3.currentState?.validate() ?? false,
        _ => false,
      };
      if (!formValid) return;
      if (_currentStep == 1 && (_cccdFrontFile == null && widget.existingRegistration?.cccdFrontUrl == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh mặt trước CCCD')),
        );
        return;
      }
      if (_currentStep == 1 && (_cccdBackFile == null && widget.existingRegistration?.cccdBackUrl == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh mặt sau CCCD')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_agreeTerms && !_isSubmitting) {
      _submit();
    } else if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng xác nhận thông tin chính xác')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_agreeTerms) return;
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không tìm thấy thông tin đăng nhập!')),
        );
        return;
      }

      final repo = ref.read(shopRegistrationRepositoryProvider);

      final existing = widget.existingRegistration;

      Future<({Uint8List bytes, String ext})?> readXFile(XFile? xf) async {
        if (xf == null) return null;
        final bytes = await xf.readAsBytes();
        return (bytes: bytes, ext: xf.name.split('.').last);
      }

      final cccdFront = await readXFile(_cccdFrontFile);
      final cccdBack = await readXFile(_cccdBackFile);
      final bizLicense = await readXFile(_bizLicenseFile);

      if (existing != null) {
        await repo.updateRegistration(
          id: existing.id,
          userId: user.id,
          shopName: _shopNameCtrl.text.trim(),
          shopDescription: _shopDescCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          cccdFrontImage: cccdFront?.bytes,
          cccdFrontExt: cccdFront?.ext,
          cccdBackImage: cccdBack?.bytes,
          cccdBackExt: cccdBack?.ext,
          fullName: _fullNameCtrl.text.trim(),
          cccdNumber: _cccdNumberCtrl.text.trim(),
          dateOfBirth: _dateOfBirth ?? DateTime.now(),
          issuedDate: _issuedDate ?? DateTime.now(),
          issuedPlace: _issuedPlaceCtrl.text.trim(),
          businessLicenseImage: bizLicense?.bytes,
          businessLicenseExt: bizLicense?.ext,
          taxCode: _taxCodeCtrl.text.trim(),
          businessType: _businessType,
          existingCccdFrontUrl: existing.cccdFrontUrl,
          existingCccdBackUrl: existing.cccdBackUrl,
          existingBusinessLicenseUrl: existing.businessLicenseUrl,
        );
      } else {
        await repo.submitRegistration(
          userId: user.id,
          shopName: _shopNameCtrl.text.trim(),
          shopDescription: _shopDescCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          cccdFrontImage: cccdFront?.bytes,
          cccdFrontExt: cccdFront?.ext,
          cccdBackImage: cccdBack?.bytes,
          cccdBackExt: cccdBack?.ext,
          fullName: _fullNameCtrl.text.trim(),
          cccdNumber: _cccdNumberCtrl.text.trim(),
          dateOfBirth: _dateOfBirth ?? DateTime.now(),
          issuedDate: _issuedDate ?? DateTime.now(),
          issuedPlace: _issuedPlaceCtrl.text.trim(),
          businessLicenseImage: bizLicense?.bytes,
          businessLicenseExt: bizLicense?.ext,
          taxCode: _taxCodeCtrl.text.trim(),
          businessType: _businessType,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký shop thành công! Đang chờ duyệt.')),
      );
      context.go(RouteNames.profilePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Shop'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Shop', 'CCCD', 'Giấy tờ', 'Xác nhận'];
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.pageHorizontal,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isActive ? Colors.black : AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  steps[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isActive || isDone
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isDone
                          ? AppColors.success
                          : AppColors.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin Shop', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _shopNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Tên shop *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên shop' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _shopDescCtrl,
            decoration: const InputDecoration(
              labelText: 'Mô tả shop',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ kinh doanh *',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giấy tờ tùy thân (CCCD)', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          _buildImagePicker(
            label: 'Ảnh mặt trước CCCD *',
            file: _cccdFrontFile,
            url: widget.existingRegistration?.cccdFrontUrl,
            onPick: () => _pickImage(_cccdFrontFile, (f) => setState(() => _cccdFrontFile = f)),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildImagePicker(
            label: 'Ảnh mặt sau CCCD *',
            file: _cccdBackFile,
            url: widget.existingRegistration?.cccdBackUrl,
            onPick: () => _pickImage(_cccdBackFile, (f) => setState(() => _cccdBackFile = f)),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _fullNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Họ và tên trên CCCD *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _cccdNumberCtrl,
            decoration: const InputDecoration(
              labelText: 'Số CCCD *',
              border: OutlineInputBorder(),
              helperText: '9 hoặc 12 số',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số CCCD';
              final cleaned = v.trim();
              if (cleaned.length != 9 && cleaned.length != 12) {
                return 'Số CCCD phải có 9 hoặc 12 số';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(
            label: 'Ngày sinh *',
            value: _dateOfBirth,
            onPick: (d) => setState(() => _dateOfBirth = d),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(
            label: 'Ngày cấp *',
            value: _issuedDate,
            onPick: (d) => setState(() => _issuedDate = d),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _issuedPlaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Nơi cấp *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập nơi cấp' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giấy tờ kinh doanh', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          _buildImagePicker(
            label: 'Ảnh giấy phép kinh doanh (nếu có)',
            file: _bizLicenseFile,
            url: widget.existingRegistration?.businessLicenseUrl,
            onPick: () => _pickImage(_bizLicenseFile, (f) => setState(() => _bizLicenseFile = f)),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _taxCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Mã số thuế (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Loại hình kinh doanh *', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...['individual', 'household', 'company'].map((type) {
            final labels = {
              'individual': 'Cá nhân',
              'household': 'Hộ kinh doanh',
              'company': 'Doanh nghiệp',
            };
            return RadioListTile<String>(
              title: Text(labels[type] ?? type),
              value: type,
              groupValue: _businessType,
              onChanged: (v) {
                if (v != null) setState(() => _businessType = v);
              },
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final bizLabels = {
      'individual': 'Cá nhân', 'household': 'Hộ kinh doanh', 'company': 'Doanh nghiệp',
    };
    final rejectionReason = widget.existingRegistration?.rejectionReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Xem lại & Xác nhận', style: AppTextStyles.headlineSmall),
        if (rejectionReason != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lý do từ chối trước đó:', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onErrorContainer)),
                const SizedBox(height: 4),
                Text(rejectionReason, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onErrorContainer)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _summaryRow('Tên shop', _shopNameCtrl.text),
        _summaryRow('Số điện thoại', _phoneCtrl.text),
        _summaryRow('Địa chỉ', _addressCtrl.text),
        _summaryRow('Họ tên trên CCCD', _fullNameCtrl.text),
        _summaryRow('Số CCCD', _cccdNumberCtrl.text),
        _summaryRow('Loại hình', bizLabels[_businessType] ?? _businessType),
        if (_taxCodeCtrl.text.isNotEmpty)
          _summaryRow('Mã số thuế', _taxCodeCtrl.text),
        const SizedBox(height: AppSpacing.lg),
        CheckboxListTile(
          value: _agreeTerms,
          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
          title: const Text('Tôi xác nhận tất cả thông tin trên đều chính xác'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            )),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required XFile? file,
    String? url,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: _XFilePreview(file: file),
                  )
                : url != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Image.network(url, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: AppColors.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('Chạm để chọn ảnh', style: AppTextStyles.bodySmall),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Chọn ngày',
        ),
      ),
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
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Quay lại'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: _handleNext,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < 3 ? 'Tiếp theo' : 'Gửi đăng ký'),
            ),
          ),
        ],
      ),
    );
  }
}

class _XFilePreview extends StatelessWidget {
  const _XFilePreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.broken_image));
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}
