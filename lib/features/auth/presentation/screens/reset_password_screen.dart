import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).updatePassword(_passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
          SizedBox(height: AppSpacing.xl),
          Text('Tạo mật khẩu mới', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Mật khẩu phải có ít nhất 6 ký tự',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),
          AppTextField(
            label: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
            obscureText: _obscurePassword,
            controller: _passwordCtrl,
            textInputAction: TextInputAction.next,
            validator: AppValidators.password,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu mới',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            onSuffixTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            obscureText: _obscureConfirm,
            controller: _confirmCtrl,
            textInputAction: TextInputAction.done,
            validator: (value) => AppValidators.confirmPassword(value, _passwordCtrl.text),
          ),
          if (authState.error != null) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                authState.error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xxl),
          AppButton.primary(
            label: 'Đặt lại mật khẩu',
            loading: authState.isLoading,
            onPressed: _submit,
          ),
          SizedBox(height: AppSpacing.md),
          AppButton.text(
            label: 'Quay lại đăng nhập',
            onPressed: () => ref.read(authProvider.notifier).resetToLogin(),
          ),
        ],
      ),
    );
  }
}
