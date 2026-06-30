import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/gym_fit_logo.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_form.dart';
import 'reset_password_screen.dart';

enum AuthPageType { login, register, forgotPassword }

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key, this.initialPage});

  final AuthPageType? initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogo(),
                SizedBox(height: AppSpacing.xxxl),
                if (authState.status == AuthStatus.emailVerification)
                  _buildVerificationSent(context, ref, authState.emailForVerification!)
                else if (authState.verificationSuccess)
                  _VerifySuccessPage(
                    onDone: () => ref.read(authProvider.notifier).resetToLogin(),
                  )
                else if (authState.status == AuthStatus.resetSent)
                  _buildResetEmailSent(context, ref)
                else if (authState.resetSuccess)
                  _buildResetSuccess(context, ref)
                else if (authState.resetToken != null)
                  const ResetPasswordScreen()
                else
                  AuthForm(initialPage: initialPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Center(
            child: const GymFitLogo(size: 44, color: AppColors.onPrimaryContainer),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'GYM FIT',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.primary,
            fontSize: 36,
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Nâng tầm sức mạnh - Vươn tới đỉnh cao',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSent(BuildContext context, WidgetRef ref, String email) {
    final cooldown = ref.watch(authProvider.select((s) => s.resendCooldown));
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(Icons.mark_email_unread_outlined, size: 40, color: AppColors.primary),
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Xác thực email', style: AppTextStyles.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Text(
          'Chúng tôi đã gửi email xác thực đến',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(email, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Vui lòng kiểm tra hộp thư đến (hoặc thư rác)\nvà nhấn vào link xác thực.\n\nSau khi xác thực, app sẽ tự động chuyển\nvề trang đăng nhập.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxl),
        AppButton.outline(
          label: cooldown > 0 ? 'Gửi lại ($cooldown giây)' : 'Gửi lại email xác thực',
          onPressed: cooldown > 0
              ? null
              : () async {
                  await ref.read(authProvider.notifier).resendVerification(email);
                },
        ),
      ],
    );
  }

  Widget _buildResetEmailSent(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(Icons.email_outlined, size: 40, color: AppColors.primary),
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Đã gửi email', style: AppTextStyles.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Text(
          'Chúng tôi đã gửi link đặt lại mật khẩu đến email của bạn.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Vui lòng kiểm tra hộp thư và nhấn vào link xác thực.\nSau khi xác thực, app sẽ tự động mở và chuyển\nđến trang đặt lại mật khẩu.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxl),
        AppButton.text(
          label: 'Quay lại đăng nhập',
          onPressed: () => ref.read(authProvider.notifier).resetToLogin(),
        ),
      ],
    );
  }

  Widget _buildResetSuccess(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(Icons.check_circle_outline, size: 40, color: AppColors.primary),
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Đặt lại mật khẩu thành công!', style: AppTextStyles.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Text(
          'Mật khẩu của bạn đã được cập nhật. Vui lòng đăng nhập với mật khẩu mới.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: 'Đăng nhập ngay',
          onPressed: () => ref.read(authProvider.notifier).resetToLogin(),
        ),
      ],
    );
  }
}

class _VerifySuccessPage extends StatefulWidget {
  const _VerifySuccessPage({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_VerifySuccessPage> createState() => _VerifySuccessPageState();
}

class _VerifySuccessPageState extends State<_VerifySuccessPage> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(Icons.check_circle_outline, size: 40, color: AppColors.primary),
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Xác thực email thành công', style: AppTextStyles.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Text(
          'Email của bạn đã được xác thực.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxl),
        Text(
          'Tự động chuyển về trang đăng nhập sau $_countdown giây',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: _countdown / 3,
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: 'Đăng nhập ngay',
          onPressed: () {
            _timer?.cancel();
            widget.onDone();
          },
        ),
      ],
    );
  }
}
