import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminBrandsScreen extends ConsumerStatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  ConsumerState<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends ConsumerState<AdminBrandsScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'name';
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
      appBar: AppBar(title: const Text('Manage brands')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminBrands(
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
                final brands = result.items;
                if (brands.isEmpty) {
                  return const Center(child: Text('No brands.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    itemCount: brands.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return ListTile(
                        title: Text(brand.name),
                        subtitle: Text(brand.slug),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showDialog(brand),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete brand?'),
                                    content: Text(
                                      'Delete "${brand.name}"?',
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
                                      .softDeleteBrand(brand.id);
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
          labelText: 'Search brands',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _onFilterChanged(),
      ),
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
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
      future: ref.read(productRepositoryProvider).getAdminBrands(
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

  Future<void> _showDialog(BrandModel? brand) async {
    final name = TextEditingController(text: brand?.name);
    final slug = TextEditingController(text: brand?.slug);
    final description = TextEditingController(text: brand?.description);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(brand == null ? 'Add brand' : 'Edit brand'),
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
              await ref.read(productRepositoryProvider).saveBrand({
                'name': name.text.trim(),
                'slug': slug.text.trim().isEmpty
                    ? _slugify(name.text)
                    : slug.text.trim(),
                'description': description.text.trim(),
              }, id: brand?.id);
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
