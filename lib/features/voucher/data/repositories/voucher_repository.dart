import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/voucher_model.dart';

class VoucherRepository {
  const VoucherRepository(this._client);

  final SupabaseClient _client;

  Future<List<VoucherModel>> getAvailableVouchers() async {
    final now = DateTime.now().toIso8601String();
    final rows = await _client
        .from(AppConstants.vouchersTable)
        .select()
        .eq('is_active', true)
        .lte('start_date', now)
        .gte('end_date', now)
        .order('end_date');

    return rows.map((row) => VoucherModel.fromJson(row)).toList();
  }

  Future<VoucherModel?> getVoucherByCode(String code) async {
    final row = await _client
        .from(AppConstants.vouchersTable)
        .select()
        .ilike('code', code.trim())
        .maybeSingle();

    return row == null ? null : VoucherModel.fromJson(row);
  }

  Future<VoucherValidationResult> validateVoucher(
    String code,
    double orderAmount,
  ) async {
    final voucher = await getVoucherByCode(code);
    if (voucher == null) {
      throw StateError('Mã giảm giá không tồn tại.');
    }
    if (!voucher.canUse) {
      throw StateError('Mã giảm giá đã hết hạn hoặc hết lượt sử dụng.');
    }
    if (orderAmount < voucher.minOrderAmount) {
      throw StateError('Đơn hàng chưa đạt giá trị tối thiểu.');
    }

    return VoucherValidationResult(
      voucher: voucher,
      discountAmount: voucher.calculateDiscount(orderAmount),
    );
  }

  Future<void> incrementUsedCount(String voucherId) async {
    final row = await _client
        .from(AppConstants.vouchersTable)
        .select('used_count')
        .eq('id', voucherId)
        .single();

    final usedCount = (row['used_count'] as num?)?.toInt() ?? 0;
    await _client
        .from(AppConstants.vouchersTable)
        .update({
          'used_count': usedCount + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', voucherId);
  }
}
