import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminBrandsScreen extends ConsumerStatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  ConsumerState<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends ConsumerState<AdminBrandsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage brands')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search brands',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BrandModel>>(
              future: repository.getAdminBrands(search: _search),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final brands = snapshot.data!;
                if (brands.isEmpty) {
                  return const Center(child: Text('No brands.'));
                }
                return ListView.separated(
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
                              await repository.softDeleteBrand(brand.id);
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
                'is_active': true,
              }, id: brand?.id);
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
