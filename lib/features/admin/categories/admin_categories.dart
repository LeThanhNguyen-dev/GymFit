import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
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
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminCategories(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                sortBy: 'sort_order',
                ascending: true,
                page: 1,
                pageSize: 1000,
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
                final tree = _buildTree(categories);
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.separated(
                          itemCount: tree.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final cat = tree[index];
                            final isSearchMode = _searchController.text.trim().isNotEmpty;
                            final depth = isSearchMode ? 0 : _getDepth(cat, categories);
                            return _buildTile(cat, depth, categories);
                          },
                        ),
                      ),
                    ),
                    _buildCountBar(result.totalCount),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<CategoryModel> _buildTree(List<CategoryModel> all) {
    if (_searchController.text.trim().isNotEmpty) {
      return all;
    }
    final parents = all.where((c) => c.parentId == null || c.parentId!.isEmpty).toList();
    if (parents.isEmpty) {
      return all;
    }
    final result = <CategoryModel>[];

    void addChildren(CategoryModel parent) {
      result.add(parent);
      if (_expanded.contains(parent.id)) {
        final children = all.where((c) => c.parentId == parent.id).toList();
        for (final child in children) {
          addChildren(child);
        }
      }
    }

    for (final p in parents) {
      addChildren(p);
    }
    return result;
  }

  int _getDepth(CategoryModel category, List<CategoryModel> all) {
    int depth = 0;
    String? currentParentId = category.parentId;
    final visited = <String>{category.id};
    while (currentParentId != null && currentParentId.isNotEmpty) {
      if (visited.contains(currentParentId)) break;
      visited.add(currentParentId);
      final parent = all.cast<CategoryModel?>().firstWhere(
        (c) => c?.id == currentParentId,
        orElse: () => null,
      );
      if (parent == null) break;
      depth++;
      currentParentId = parent.parentId;
    }
    return depth;
  }

  Widget _buildTile(CategoryModel category, int depth, List<CategoryModel> all) {
    final repository = ref.read(productRepositoryProvider);
    final isSearchMode = _searchController.text.trim().isNotEmpty;
    final hasChildren = isSearchMode ? false : all.any((c) => c.parentId == category.id);
    final isExpanded = _expanded.contains(category.id);
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + depth * 24.0, right: 16.0),
      leading: hasChildren
          ? IconButton(
              icon: Icon(isExpanded ? Icons.expand_more : Icons.chevron_right),
              onPressed: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(category.id);
                } else {
                  _expanded.add(category.id);
                }
              }),
            )
          : const SizedBox(width: 48),
      title: Text(category.name),
      subtitle: Text(category.slug),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${all.where((c) => c.parentId == category.id).length} sub',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
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
                  content: Text('Delete "${category.name}" and all subcategories?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await repository.softDeleteCategory(category.id);
                if (mounted) setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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

  Widget _buildCountBar(int totalItems) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '$totalItems items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: slug, decoration: const InputDecoration(labelText: 'Slug')),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            await ref.read(productRepositoryProvider).saveCategory({
              'name': name.text.trim(),
              'slug': slug.text.trim().isEmpty ? _slugify(name.text) : slug.text.trim(),
              'description': description.text.trim(),
            }, id: category?.id);
            if (mounted) setState(() {});
            if (context.mounted) Navigator.of(context).pop();
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}

String _slugify(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp('(^-|-\$)'), '');
}
