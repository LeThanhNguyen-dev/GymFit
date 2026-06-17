import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  return repo.searchProducts(query);
});

final searchSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return [];
  final repo = ref.watch(productRepositoryProvider);
  return repo.getSearchSuggestions(query);
});

// ── Search History Notifier (Riverpod 3.x) ────────────────────────────────────

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'recent_searches';
  SharedPreferences? _prefs;

  @override
  List<String> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getStringList(_key);
    if (saved != null) {
      state = saved;
    }
  }

  void addSearchTerm(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    
    final newState = [
      trimmed,
      ...state.where((item) => item != trimmed),
    ].take(10).toList();
    
    state = newState;
    _prefs?.setStringList(_key, newState);
  }

  void removeSearchTerm(String term) {
    final newState = state.where((item) => item != term).toList();
    state = newState;
    _prefs?.setStringList(_key, newState);
  }

  void clearHistory() {
    state = [];
    _prefs?.remove(_key);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
