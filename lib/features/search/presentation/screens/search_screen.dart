import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() => _hasSubmitted = true);
    ref.read(searchHistoryProvider.notifier).addSearchTerm(trimmed);
    ref.read(searchQueryProvider.notifier).set(trimmed);
  }

  void _onSearchChanged(String value) {
    setState(() => _hasSubmitted = false);
    ref.read(searchQueryProvider.notifier).set(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final history = ref.watch(searchHistoryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body: History, Suggestions or Results ──────────────────────────────
            Expanded(
              child: query.isEmpty
                  ? _SearchHistorySection(
                      history: history,
                      onTapHistory: (term) {
                        _searchController.text = term;
                        _onSearchSubmitted(term);
                      },
                      onRemoveHistory: (term) {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .removeSearchTerm(term);
                      },
                      onClearAll: () {
                        ref.read(searchHistoryProvider.notifier).clearHistory();
                      },
                    )
                  : (!_hasSubmitted
                        ? _SearchSuggestionsSection(
                            onTapSuggestion: (term) {
                              _searchController.text = term;
                              _onSearchSubmitted(term);
                            },
                          )
                        : _SearchResultsSection(searchResults: searchResults)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Suggestions Section ────────────────────────────────────────────────
class _SearchSuggestionsSection extends ConsumerWidget {
  const _SearchSuggestionsSection({required this.onTapSuggestion});
  final ValueChanged<String> onTapSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(searchSuggestionsProvider);

    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return const Center(child: Text('Không tìm thấy gợi ý nào.'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gợi ý AI',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Các từ khóa được Groq gợi ý theo catalog GymFit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (term) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(term),
                  trailing: const Icon(Icons.north_west_rounded, size: 18),
                  onTap: () => onTapSuggestion(term),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Search History Section ────────────────────────────────────────────────────

class _SearchHistorySection extends StatelessWidget {
  const _SearchHistorySection({
    required this.history,
    required this.onTapHistory,
    required this.onRemoveHistory,
    required this.onClearAll,
  });

  final List<String> history;
  final ValueChanged<String> onTapHistory;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Tìm kiếm sản phẩm yêu thích',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tìm kiếm gần đây',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('Xóa tất cả', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, i) {
              final term = history[i];
              return ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onRemoveHistory(term),
                ),
                onTap: () => onTapHistory(term),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Search Results Section ────────────────────────────────────────────────────

class _SearchResultsSection extends ConsumerWidget {
  const _SearchResultsSection({required this.searchResults});
  final AsyncValue<List<ProductModel>> searchResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return searchResults.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => const ProductCardShimmer(),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy sản phẩm',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => ProductCard(
            product: products[i],
            onTap: () => context.push('/products/${products[i].id}'),
          ),
        );
      },
    );
  }
}
