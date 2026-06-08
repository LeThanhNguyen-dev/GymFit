import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/voucher_model.dart';
import '../data/repositories/voucher_repository.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return VoucherRepository(ref.watch(supabaseClientProvider));
});

final availableVouchersProvider = FutureProvider<List<VoucherModel>>((ref) {
  return ref.watch(voucherRepositoryProvider).getAvailableVouchers();
});

final appliedVoucherProvider =
    NotifierProvider<AppliedVoucherNotifier, VoucherModel?>(
      AppliedVoucherNotifier.new,
    );

final voucherOrderAmountProvider =
    NotifierProvider<VoucherOrderAmountNotifier, double>(
      VoucherOrderAmountNotifier.new,
    );

final discountAmountProvider = Provider<double>((ref) {
  final voucher = ref.watch(appliedVoucherProvider);
  final orderAmount = ref.watch(voucherOrderAmountProvider);
  return voucher?.calculateDiscount(orderAmount) ?? 0;
});

class AppliedVoucherNotifier extends Notifier<VoucherModel?> {
  @override
  VoucherModel? build() => null;

  void setVoucher(VoucherModel? voucher) {
    state = voucher;
  }
}

class VoucherOrderAmountNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void setAmount(double amount) {
    state = amount;
  }
}
