import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../providers/comparison_providers.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(comparisonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('So sánh sản phẩm'),
        actions: [
          if (products.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(comparisonProvider.notifier).clear();
              },
              icon: const Icon(Icons.clear_all, color: Colors.red),
              label: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.compare_arrows, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Chưa có sản phẩm nào để so sánh'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppButton.primary(
                      label: 'Thêm sản phẩm khác',
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  dataRowMaxHeight: double.infinity,
                  headingRowHeight: 60,
                  columns: [
                    const DataColumn(label: Text('Thông tin', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...products.map(
                      (p) => DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  ref.read(comparisonProvider.notifier).removeProduct(p.id);
                                  if (products.length == 1) {
                                    context.pop();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        const DataCell(Text('Hình ảnh')),
                        ...products.map(
                          (p) => DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: AppImage(
                                imageUrl: p.images.isNotEmpty ? p.images.first.url : '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Tên sản phẩm')),
                        ...products.map(
                          (p) => DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Giá')),
                        ...products.map(
                          (p) => DataCell(
                            PriceText(
                              p.basePrice,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Đánh giá')),
                        ...products.map(
                          (p) => DataCell(
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(p.averageRating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Mô tả')),
                        ...products.map(
                          (p) => DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                p.description ?? 'Chưa có mô tả',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('')),
                        ...products.map(
                          (p) => DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: AppButton.primary(
                                label: 'Mua ngay',
                                expanded: false,
                                onPressed: () => context.push('/products/${p.id}'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
