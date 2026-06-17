import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/profile_model.dart';
import '../../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  XFile? _selectedImage;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final profileRepo = ref.read(profileRepositoryProvider);
    final currentProfile = ref.read(profileProvider).asData?.value;

    try {
      String? avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = await profileRepo.uploadAvatar(_selectedImage!);
      }

      if (currentProfile != null) {
        final updated = currentProfile.copyWith(
          fullName: _nameController.text.trim().isEmpty
              ? currentProfile.fullName
              : _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? currentProfile.phone
              : _phoneController.text.trim(),
          avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
        );

        await profileRepo.updateProfile(updated);
      }

      setState(() => _saving = false);

      if (mounted) {
        ref.invalidate(profileProvider);
        showAppSnackbar(context, message: 'Cập nhật hồ sơ thành công', type: SnackbarType.success);
        context.go(RouteNames.profilePath);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        showAppSnackbar(context, message: 'Lỗi: $e', type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(
          child: Text('Lỗi: $error', style: AppTextStyles.bodyLarge),
        ),
        data: (profile) => _buildForm(profile),
      ),
    );
  }

  Widget _buildForm(ProfileModel profile) {
    _nameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Avatar
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            )
                          : profile.avatarUrl != null
                              ? AppImage(
                                  imageUrl: profile.avatarUrl,
                                  width: 112,
                                  height: 112,
                                )
                              : Text(
                                  profile.initials,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: AppColors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chạm để đổi ảnh đại diện',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Email (read-only)
            AppTextField(
              label: 'Email',
              hintText: profile.email,
              enabled: false,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: AppSpacing.md),

            // Full name
            AppTextField(
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                  return 'Tên phải có ít nhất 2 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Phone
            AppTextField(
              label: 'Số điện thoại',
              hintText: 'Nhập số điện thoại',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            AppButton.primary(
              label: 'Lưu thay đổi',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
