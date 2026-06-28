import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/wishlist_model.dart';
import '../data/repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(supabaseClientProvider));
});

final wishlistItemsProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItemModel>>(
  WishlistNotifier.new,
);

final isInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final items =
      ref.watch(wishlistItemsProvider).value ?? const <WishlistItemModel>[];
  return items.any((item) => item.productId == productId);
});

final wishlistCountProvider = Provider<int>((ref) {
  final items =
      ref.watch(wishlistItemsProvider).value ?? const <WishlistItemModel>[];
  return items.length;
});

class WishlistNotifier extends AsyncNotifier<List<WishlistItemModel>> {
  @override
  FutureOr<List<WishlistItemModel>> build() {
    return _repository.getWishlistItems(_userId);
  }

  WishlistRepository get _repository => ref.read(wishlistRepositoryProvider);

  String get _userId {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      throw StateError('Ban can dang nhap de su dung danh sach yeu thich.');
    }
    return user.id;
  }

  Future<void> loadWishlist() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getWishlistItems(_userId));
  }

  Future<void> toggleWishlist(String productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final exists = await _repository.isInWishlist(_userId, productId);
      if (exists) {
        await _repository.removeFromWishlist(_userId, productId);
      } else {
        await _repository.addToWishlist(_userId, productId);
      }
      return _repository.getWishlistItems(_userId);
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.removeFromWishlist(_userId, productId);
      return _repository.getWishlistItems(_userId);
    });
  }
}
