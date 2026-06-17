import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'sort_order';
  bool _ascending = true;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminCategories(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                sortBy: _sortBy,
                ascending: _ascending,
                page: _page,
                pageSize: 50,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data!;
                final categories = result.items;
                if (categories.isEmpty) {
                  return const Center(child: Text('No categories.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(category.name),
                        subtitle: Text(category.slug),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showDialog(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete category?'),
                                    content: Text(
                                      'Delete "${category.name}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await repository
                                      .softDeleteCategory(category.id);
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search categories',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('sort_order', 'Sort order'),
      SortOption('sort_order_desc', 'Reverse'),
      SortOption('name', 'Name A-Z'),
      SortOption('name_desc', 'Name Z-A'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('created_at_desc', 'Mới nhất'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SortDropdown(
        value: currentKey,
        options: sortOptions,
        onChanged: (key) {
          setState(() {
            if (key.endsWith('_desc')) {
              _sortBy = key.replaceAll('_desc', '');
              _ascending = false;
            } else {
              _sortBy = key;
              _ascending = true;
            }
            _page = 1;
          });
        },
      ),
    );
  }

  Widget _buildPagination() {
    return FutureBuilder(
      future: ref.read(productRepositoryProvider).getAdminCategories(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
        pageSize: 50,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        final totalPages = (result.totalCount / 50).ceil();
        return PaginationBar(
          page: _page,
          totalPages: totalPages,
          totalItems: result.totalCount,
          onPageChanged: (p) => setState(() => _page = p),
        );
      },
    );
  }

  Future<void> _showDialog(CategoryModel? category) async {
    final name = TextEditingController(text: category?.name);
    final slug = TextEditingController(text: category?.slug);
    final description = TextEditingController(text: category?.description);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add category' : 'Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: slug,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).saveCategory({
                'name': name.text.trim(),
                'slug': slug.text.trim().isEmpty
                    ? _slugify(name.text)
                    : slug.text.trim(),
                'description': description.text.trim(),
              }, id: category?.id);
              if (mounted) setState(() {});
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

String _slugify(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('(^-|-\$)'), '');
}
