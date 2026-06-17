import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/enums/database_enums.dart';
import '../../../../register_shop/data/models/shop_registration_model.dart';
import '../../../../register_shop/providers/shop_registration_providers.dart';

class AdminShopDetailScreen extends ConsumerWidget {
  const AdminShopDetailScreen({super.key, required this.registrationId});

  final String registrationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRegistrations = ref.watch(allShopRegistrationsProvider);

    return allRegistrations.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      data: (items) {
        final reg = items.where((r) => r.id == registrationId).firstOrNull;
        if (reg == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đăng ký')),
            body: const Center(child: Text('Không tìm thấy')),
          );
        }
        return _DetailContent(registration: reg);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.registration});

  final ShopRegistrationModel registration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = registration.status == ShopRegistrationStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đăng ký'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _section('Thông tin Shop', [
            _row('Tên shop', registration.shopName),
            if (registration.shopDescription != null)
              _row('Mô tả', registration.shopDescription!),
            _row('Số điện thoại', registration.phoneNumber),
            _row('Địa chỉ', registration.address),
          ]),
          const SizedBox(height: AppSpacing.md),
          _section('CCCD', [
            _row('Họ tên', registration.fullName),
            _row('Số CCCD', registration.cccdNumber),
            _row('Ngày sinh', _fmt(registration.dateOfBirth)),
            _row('Ngày cấp', _fmt(registration.issuedDate)),
            _row('Nơi cấp', registration.issuedPlace),
          ]),
          if (registration.cccdFrontUrl != null || registration.cccdBackUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            _section('Ảnh CCCD', [
              if (registration.cccdFrontUrl != null)
                _imageTile(context, 'Mặt trước', registration.cccdFrontUrl!),
              if (registration.cccdBackUrl != null)
                _imageTile(context, 'Mặt sau', registration.cccdBackUrl!),
            ]),
          ],
          const SizedBox(height: AppSpacing.md),
          _section('Giấy tờ kinh doanh', [
            _row('Loại hình', registration.businessTypeDisplay),
            if (registration.taxCode != null)
              _row('Mã số thuế', registration.taxCode!),
            if (registration.businessLicenseUrl != null)
              _imageTile(context, 'Giấy phép KD', registration.businessLicenseUrl!),
          ]),
          const SizedBox(height: AppSpacing.md),
          _section('Trạng thái', [
            _row('Trạng thái', registration.statusDisplay),
            if (registration.rejectionReason != null)
              _row('Lý do từ chối', registration.rejectionReason!),
          ]),
          const SizedBox(height: AppSpacing.xxl),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(
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

  Widget _imageTile(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          )),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Duyệt đơn đăng ký shop "${registration.shopName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Duyệt')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(shopRegistrationRepositoryProvider);
      await repo.approveRegistration(registration.id);
      if (!context.mounted) return;
      ref.invalidate(allShopRegistrationsProvider);
      ref.invalidate(shopRegistrationsByStatusProvider('pending'));
      ref.invalidate(shopRegistrationsByStatusProvider('approved'));
      ref.invalidate(shopRegistrationsByStatusProvider('rejected'));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối đăng ký'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, reasonCtrl.text.trim());
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    try {
      final repo = ref.read(shopRegistrationRepositoryProvider);
      await repo.rejectRegistration(registration.id, reason);
      if (!context.mounted) return;
      ref.invalidate(allShopRegistrationsProvider);
      ref.invalidate(shopRegistrationsByStatusProvider('pending'));
      ref.invalidate(shopRegistrationsByStatusProvider('approved'));
      ref.invalidate(shopRegistrationsByStatusProvider('rejected'));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }
}
