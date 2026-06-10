import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

// ── Search Query (Riverpod 3.x, replaces StateProvider) ───────────────────────

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider.autoDispose<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

// Kết quả tìm kiếm từ Supabase
final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(productRepositoryProvider);
  return repo.searchProducts(query.trim());
});

// ── Search History Notifier (Riverpod 3.x) ────────────────────────────────────

class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addSearchTerm(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((item) => item != trimmed),
    ].take(10).toList();
  }

  void removeSearchTerm(String term) {
    state = state.where((item) => item != term).toList();
  }

  void clearHistory() {
    state = [];
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
