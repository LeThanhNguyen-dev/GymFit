import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../support/providers/support_provider.dart';
import '../../providers/service_providers.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final _descCtrl = TextEditingController();
  bool _showForm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceBySlugProvider(widget.slug));

    return serviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Dịch vụ')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Dịch vụ')),
        body: Center(child: Text('Lỗi: $e')),
      ),
      data: (service) {
        if (service == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dịch vụ')),
            body: const Center(child: Text('Không tìm thấy dịch vụ')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(service.name)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (service.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      service.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: AppColors.surfaceContainerLow,
                        child: Icon(Icons.fitness_center,
                            size: 64, color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(Icons.fitness_center,
                        size: 64, color: AppColors.primary),
                  ),
                SizedBox(height: AppSpacing.xl),
                Text(service.name,
                    style: AppTextStyles.headlineMedium),
                SizedBox(height: AppSpacing.md),
                if (service.description != null)
                  Text(service.description!,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.onSurfaceVariant)),
                SizedBox(height: AppSpacing.xxl),
                if (!_showForm) ...[
                  AppButton.primary(
                    label: 'Đăng ký tư vấn',
                    onPressed: () => setState(() => _showForm = true),
                  ),
                ] else ...[
                  AppTextField(
                    label: 'Nội dung',
                    hintText:
                        'Nhập thông tin bạn muốn tư vấn...',
                    controller: _descCtrl,
                    maxLines: 4,
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppButton.primary(
                    label: 'Gửi yêu cầu',
                    loading: _submitting,
                    onPressed: _handleSubmit,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AppButton.text(
                    label: 'Hủy',
                    onPressed: () => setState(() {
                      _showForm = false;
                      _descCtrl.clear();
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(createTicketProvider.notifier).submit(
            userId: user.id,
            subject: 'Đăng ký tư vấn dịch vụ',
            description: _descCtrl.text.trim(),
            category: 'other',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yêu cầu đã được gửi. Chúng tôi sẽ liên hệ bạn sớm!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/support');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
