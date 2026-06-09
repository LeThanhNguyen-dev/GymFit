import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

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
                if (authState.emailForVerification != null)
                  _buildVerificationSent(context, ref, authState.emailForVerification!)
                else
                  const AuthForm(),
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
            child: Text(
              'GYM',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
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
        Text(
          'Xác thực email',
          style: AppTextStyles.headlineMedium,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'Chúng tôi đã gửi email xác thực đến',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          email,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Vui lòng kiểm tra hộp thư đến (hoặc thư rác) và nhấn vào link xác thực, sau đó đăng nhập lại.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: 'Đã xác thực, đăng nhập ngay',
          onPressed: () {
            ref.read(authProvider.notifier).clearError();
          },
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton.text(
          label: 'Gửi lại email xác thực',
          onPressed: () {
            ref.read(authProvider.notifier).resendVerification();
          },
        ),
      ],
    );
  }
}
