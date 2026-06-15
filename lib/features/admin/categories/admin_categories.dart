import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search categories',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: repository.getAdminCategories(search: _search),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!;
                if (categories.isEmpty) {
                  return const Center(child: Text('No categories.'));
                }
                return ListView.separated(
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
                              await repository.softDeleteCategory(category.id);
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
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
                'is_active': true,
              }, id: category?.id);
              if (mounted) {
                setState(() {});
              }
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
