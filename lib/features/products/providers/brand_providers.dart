import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/product_model.dart';
import '../data/repositories/brand_repository.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository(ref.watch(supabaseClientProvider));
});

final brandListProvider =
    FutureProvider.autoDispose<List<BrandModel>>((ref) async {
  final repo = ref.watch(brandRepositoryProvider);
  return repo.getAll();
});

// ── Selected Brand (Riverpod 3.x, replaces StateProvider) ─────────────────────

class _SelectedBrandNotifier extends Notifier<BrandModel?> {
  @override
  BrandModel? build() => null;

  void select(BrandModel? brand) => state = brand;
  void clear() => state = null;
}

final selectedBrandProvider =
    NotifierProvider<_SelectedBrandNotifier, BrandModel?>(
  _SelectedBrandNotifier.new,
);
