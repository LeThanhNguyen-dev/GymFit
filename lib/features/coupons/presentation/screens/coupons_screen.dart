import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/coupon_model.dart';
import '../widgets/coupon_card.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  // Mock data for coupons - Replace with real provider data
  static const List<VoucherModel> mockCoupons = [
    VoucherModel(
      id: '1',
      code: 'SAVE20',
      name: 'Giảm 20% cho tất cả',
      description: 'Giảm 20% khi mua bất kỳ sản phẩm nào',
      type: VoucherType.percentage,
      discountValue: 20,
      scope: VoucherScope.global,
      isActive: true,
      usedCount: 45,
      usageLimit: 100,
    ),
    VoucherModel(
      id: '2',
      code: 'FLAT50K',
      name: 'Giảm 50.000đ',
      description: 'Giảm 50.000đ cho đơn hàng từ 200.000đ',
      type: VoucherType.fixed,
      discountValue: 50000,
      scope: VoucherScope.global,
      minOrderAmount: 200000,
      isActive: true,
      usedCount: 120,
      usageLimit: 200,
    ),
    VoucherModel(
      id: '3',
      code: 'SUMMER30',
      name: 'Mùa hè - Giảm 30%',
      description: 'Ưu đãi mùa hè - Giảm 30% tối đa 500.000đ',
      type: VoucherType.percentage,
      discountValue: 30,
      scope: VoucherScope.global,
      maxDiscountAmount: 500000,
      isActive: true,
      usedCount: 200,
      usageLimit: 300,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã khuyến mãi'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh coupons from provider
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            // Info banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Sao chép mã khuyến mãi và sử dụng trong giỏ hàng',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(height: AppSpacing.md),

            // Coupons list
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              sliver: SliverList.separated(
                itemCount: mockCoupons.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => CouponCard(
                  coupon: mockCoupons[index],
                  onCopy: () => _copyCouponCode(mockCoupons[index].code),
                ),
              ),
            ),
            const SliverToBoxAdapter(height: AppSpacing.pageHorizontal),
          ],
        ),
      ),
    );
  }

  void _copyCouponCode(String code) {
    // TODO: Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

