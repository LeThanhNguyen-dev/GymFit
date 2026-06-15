import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/models/product_model.dart';
import '../../products/providers/product_providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search products',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: repository.getAdminProducts(search: _search),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const Center(child: Text('No products.'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.status.name} - ${product.basePrice.round()}d',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showProductDialog(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repository.softDeleteProduct(product.id);
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
        onPressed: () => _showProductDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showProductDialog(ProductModel? product) async {
    final name = TextEditingController(text: product?.name);
    final slug = TextEditingController(text: product?.slug);
    final categoryId = TextEditingController(text: product?.categoryId);
    final brandId = TextEditingController(text: product?.brandId);
    final price = TextEditingController(
      text: product?.basePrice.toString() ?? '0',
    );
    var featured = product?.isFeatured ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(product == null ? 'Add product' : 'Edit product'),
          content: SingleChildScrollView(
            child: Column(
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
                  controller: categoryId,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                ),
                TextField(
                  controller: brandId,
                  decoration: const InputDecoration(
                    labelText: 'Brand ID optional',
                  ),
                ),
                TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Base price'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: featured,
                  onChanged: (value) => setLocalState(() => featured = value),
                  title: const Text('Featured'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(productRepositoryProvider).saveProduct({
                  'name': name.text.trim(),
                  'slug': slug.text.trim(),
                  'category_id': categoryId.text.trim(),
                  'brand_id': brandId.text.trim().isEmpty
                      ? null
                      : brandId.text.trim(),
                  'base_price': double.tryParse(price.text.trim()) ?? 0,
                  'status': 'active',
                  'is_featured': featured,
                }, id: product?.id);
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
