import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';
import '../screens/auth_screen.dart';

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key, this.initialPage});

  final AuthPageType? initialPage;

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isRegister = false;
  late bool _showForgotPassword;

  @override
  void initState() {
    super.initState();
    _showForgotPassword = widget.initialPage == AuthPageType.forgotPassword;
    if (widget.initialPage == AuthPageType.register) {
      _isRegister = true;
    }
  }
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);
    auth.clearError();

    if (_showForgotPassword) {
      auth.forgotPassword(_emailCtrl.text.trim());
    } else if (_isRegister) {
      auth.register(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
    } else {
      auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStateData>(authProvider, (previous, next) {
      if (next.successMessage != null && _isRegister) {
        setState(() {
          _isRegister = false;
          _passwordCtrl.clear();
          _confirmPasswordCtrl.clear();
        });
      }
    });

    final authState = ref.watch(authProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showForgotPassword)
            _buildForgotPasswordHeader()
          else
            _buildToggle(),
          SizedBox(height: AppSpacing.xxl),
          if (_isRegister && !_showForgotPassword)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                label: 'Họ và tên',
                hintText: 'Nhập họ và tên của bạn',
                prefixIcon: Icons.person_outline,
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppTextField(
              label: 'Email',
              hintText: 'Nhập email của bạn',
              prefixIcon: Icons.email_outlined,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _isRegister || _showForgotPassword
                  ? TextInputAction.next
                  : TextInputAction.next,
              validator: AppValidators.email,
            ),
          ),
          if (!_showForgotPassword)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                prefixIcon: Icons.lock_outlined,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                obscureText: _obscurePassword,
                controller: _passwordCtrl,
                textInputAction: _isRegister
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: _showForgotPassword ? null : AppValidators.password,
              ),
            ),
          if (_isRegister && !_showForgotPassword)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                label: 'Xác nhận mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                prefixIcon: Icons.lock_outlined,
                suffixIcon: _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                obscureText: _obscureConfirm,
                controller: _confirmPasswordCtrl,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    AppValidators.confirmPassword(value, _passwordCtrl.text),
              ),
            ),
          if (!_showForgotPassword && !_isRegister)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showForgotPassword = true),
                child: Text(
                  'Quên mật khẩu?',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (authState.error != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  authState.error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          if (authState.successMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  authState.successMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.sm),
          AppButton.primary(
            label: _buildButtonLabel(),
            loading: authState.isLoading,
            onPressed: _submit,
          ),
          SizedBox(height: AppSpacing.md),
          if (_showForgotPassword) _buildBackToLogin() else _buildSwitchMode(),
        ],
      ),
    );
  }

  String _buildButtonLabel() {
    if (_showForgotPassword) return 'Gửi yêu cầu';
    return _isRegister ? 'Đăng ký' : 'Đăng nhập';
  }

  Widget _buildForgotPasswordHeader() {
    return Column(
      children: [
        Text('Quên mật khẩu', style: AppTextStyles.headlineSmall),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Nhập email của bạn để nhận link đặt lại mật khẩu',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quay lại',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: AppSpacing.xxs),
        GestureDetector(
          onTap: () => setState(() {
            _showForgotPassword = false;
            ref.read(authProvider.notifier).clearError();
          }),
          child: Text(
            'Đăng nhập',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: EdgeInsets.all(AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRegister = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: !_isRegister ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Đăng nhập',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: !_isRegister
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRegister = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isRegister ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Đăng ký',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: _isRegister
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: AppSpacing.xxs),
        GestureDetector(
          onTap: () => setState(() {
            _isRegister = !_isRegister;
            ref.read(authProvider.notifier).clearError();
          }),
          child: Text(
            _isRegister ? 'Đăng nhập' : 'Đăng ký',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
