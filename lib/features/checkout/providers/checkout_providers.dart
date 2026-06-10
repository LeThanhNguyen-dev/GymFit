import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../address/data/models/address_model.dart';
import '../data/models/checkout_model.dart';
import '../data/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(supabaseClientProvider));
});

final checkoutDataProvider =
    NotifierProvider<CheckoutDataNotifier, CheckoutData?>(
      CheckoutDataNotifier.new,
    );

final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, AddressModel?>(
      SelectedAddressNotifier.new,
    );

final paymentMethodProvider = NotifierProvider<PaymentMethodNotifier, String>(
  PaymentMethodNotifier.new,
);

final orderNoteProvider = NotifierProvider<OrderNoteNotifier, String>(
  OrderNoteNotifier.new,
);

final shippingFeeProvider = FutureProvider<double>((ref) {
  final address = ref.watch(selectedAddressProvider);
  if (address == null) return 30000;
  return ref.watch(checkoutRepositoryProvider).calculateShippingFee(address.id);
});

final checkoutTotalProvider = Provider<double>((ref) {
  final data = ref.watch(checkoutDataProvider);
  final shippingFee = ref.watch(shippingFeeProvider).value ?? 30000;
  return (data?.total ?? 0) + shippingFee;
});

final createOrderProvider =
    AsyncNotifierProvider<CreateOrderNotifier, CheckoutResult?>(
      CreateOrderNotifier.new,
    );

class CreateOrderNotifier extends AsyncNotifier<CheckoutResult?> {
  @override
  Future<CheckoutResult?> build() async => null;

  Future<CheckoutResult> submit() async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    final data = ref.read(checkoutDataProvider);
    final address = ref.read(selectedAddressProvider);
    if (user == null) throw StateError('Ban can dang nhap de dat hang.');
    if (data == null) throw StateError('Chua co du lieu checkout.');
    if (address == null) throw StateError('Vui long chon dia chi giao hang.');

    final request = CheckoutRequest(
      userId: user.id,
      checkoutData: data,
      address: address,
      paymentMethod: ref.read(paymentMethodProvider),
      shippingFee: ref.read(shippingFeeProvider).value ?? 30000,
      note: ref.read(orderNoteProvider),
    );

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(checkoutRepositoryProvider).createOrder(request),
    );
    state = result;
    return result.requireValue;
  }
}

class CheckoutDataNotifier extends Notifier<CheckoutData?> {
  @override
  CheckoutData? build() => null;

  void setData(CheckoutData? data) {
    state = data;
  }
}

class SelectedAddressNotifier extends Notifier<AddressModel?> {
  @override
  AddressModel? build() => null;

  void setAddress(AddressModel? address) {
    state = address;
  }
}

class PaymentMethodNotifier extends Notifier<String> {
  @override
  String build() => 'cod';

  void setMethod(String method) {
    state = method;
  }
}

class OrderNoteNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setNote(String note) {
    state = note;
  }
}
