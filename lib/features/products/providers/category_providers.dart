import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/product_model.dart';
import '../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

final categoryListProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

// ── Selected Category (Riverpod 3.x, replaces StateProvider) ──────────────────

class _SelectedCategoryNotifier extends Notifier<CategoryModel?> {
  @override
  CategoryModel? build() => null;

  void select(CategoryModel? category) => state = category;
  void clear() => state = null;
}

final selectedCategoryProvider =
    NotifierProvider<_SelectedCategoryNotifier, CategoryModel?>(
  _SelectedCategoryNotifier.new,
);
