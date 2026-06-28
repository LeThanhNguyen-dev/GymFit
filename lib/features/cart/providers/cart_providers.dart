import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../products/providers/product_providers.dart';
import '../data/models/cart_model.dart';
import '../data/repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(productRepositoryProvider),
  );
});

final cartItemsProvider =
    AsyncNotifierProvider<CartNotifier, List<CartItemModel>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? const <CartItemModel>[];
  return items.fold<int>(0, (total, item) => total + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? const <CartItemModel>[];
  return items.fold<double>(0, (total, item) => total + item.itemTotal);
});

final cartSummaryProvider = Provider<CartSummary>((ref) {
  return CartSummary(
    subtotal: ref.watch(cartTotalProvider),
    itemCount: ref.watch(cartCountProvider),
  );
});

class CartNotifier extends AsyncNotifier<List<CartItemModel>> {
  @override
  FutureOr<List<CartItemModel>> build() {
    return _repository.getCartItems(_userId);
  }

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  String get _userId {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      throw StateError('Ban can dang nhap de su dung gio hang.');
    }
    return user.id;
  }

  Future<void> loadCart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getCartItems(_userId));
  }

  Future<void> addToCart(
    String productId,
    String variantId,
    int quantity,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.addToCart(_userId, productId, variantId, quantity);
      return _repository.getCartItems(_userId);
    });
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateQuantity(cartItemId, quantity);
      return _repository.getCartItems(_userId);
    });
  }

  Future<void> removeItem(String cartItemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.removeItem(cartItemId);
      return _repository.getCartItems(_userId);
    });
  }

  Future<void> clearCart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.clearCart(_userId);
      return <CartItemModel>[];
    });
  }

  Future<List<CartItemModel>> checkStock() {
    return _repository.checkStockAvailability(_userId);
  }
}
