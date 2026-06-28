import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/models/product_model.dart';
import '../widgets/product_card.dart';

class ShopProductsScreen extends ConsumerStatefulWidget {
  const ShopProductsScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  final String sellerId;
  final String sellerName;

  @override
  ConsumerState<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends ConsumerState<ShopProductsScreen> {
  String? _avatarUrl;
  String? _description;
  int _productCount = 0;
  int _totalSold = 0;
  DateTime? _joinedAt;

  List<ProductModel> _products = [];
  List<ProductModel> _bestSellers = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  String _sortBy = 'created_at';
  bool _ascending = false;

  static const String _productSelect =
      'id, category_id, seller_id, brand_id, name, slug, sku, short_description, description, base_price, compare_at_price, cost_price, status, is_featured, is_digital, requires_shipping, weight_grams, length_cm, width_cm, height_cm, tags, attributes, seo_title, seo_description, average_rating, total_reviews, total_sold, view_count, metadata, created_at, updated_at, category:categories(id, name, slug), brand:brands(id, name, slug), images:product_images(*), variants:product_variants(*)';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final profileFuture = client
          .from('profiles')
          .select('avatar_url, created_at')
          .eq('id', widget.sellerId)
          .maybeSingle();
      final shopFuture = client
          .from('shop_registrations')
          .select('shop_description')
          .eq('user_id', widget.sellerId)
          .eq('status', 'approved')
          .maybeSingle();
      final productsFuture = client
          .from('products')
          .select('id')
          .eq('seller_id', widget.sellerId)
          .inFilter('status', ['active', 'out_of_stock']);
      final soldFuture = client
          .from('order_items')
          .select('quantity')
          .eq('seller_id', widget.sellerId)
          .eq('store_status', 'delivered');
      final bestFuture = client
          .from('products')
          .select(_productSelect)
          .eq('seller_id', widget.sellerId)
          .inFilter('status', ['active', 'out_of_stock'])
          .order('total_sold', ascending: false)
          .limit(5);

      // Fetch categories: get product category_ids first, then fetch names
      final catIdsRows = await client
          .from('products')
          .select('category_id')
          .eq('seller_id', widget.sellerId)
          .inFilter('status', ['active', 'out_of_stock']);
      final catIds = catIdsRows
          .map((r) => r['category_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final results = await Future.wait<dynamic>([
        profileFuture,
        shopFuture,
        productsFuture,
        soldFuture,
        bestFuture,
        catIds.isEmpty
            ? Future.value(<dynamic>[])
            : client.from('categories').select('id, name').inFilter('id', catIds),
      ]);
      if (!mounted) return;

      final profile = results[0] as Map<String, dynamic>?;
      final shop = results[1] as Map<String, dynamic>?;
      final prodRows = results[2] as List<dynamic>;
      final soldRows = results[3] as List<dynamic>;
      final bestRows = results[4] as List<dynamic>;
      final catRows = results[5] as List<dynamic>;

      setState(() {
        _avatarUrl = profile?['avatar_url'] as String?;
        _joinedAt = profile?['created_at'] != null ? DateTime.tryParse(profile!['created_at'] as String) : null;
        _description = shop?['shop_description'] as String?;
        _productCount = prodRows.length;
        _totalSold = soldRows.fold<int>(0, (sum, r) => sum + ((r as Map)['quantity'] as int? ?? 0));
        _bestSellers = bestRows.map((r) => ProductModel.fromJson(r as Map<String, dynamic>)).toList();
        _categories = catRows.map((r) => r as Map<String, dynamic>).toList();
        _isLoading = false;
      });

      await _loadProducts();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> _soldCounts = {};

  Future<void> _loadProducts() async {
    final client = ref.read(supabaseClientProvider);
    try {
      var q = client
          .from('products')
          .select(_productSelect)
          .eq('seller_id', widget.sellerId)
          .inFilter('status', ['active', 'out_of_stock']);
      if (_selectedCategoryId != null) {
        q = q.eq('category_id', _selectedCategoryId!);
      }
      final results = await Future.wait<dynamic>([
        q.order(_sortBy, ascending: _ascending),
        client
            .from('order_items')
            .select('product_id, quantity')
            .eq('seller_id', widget.sellerId)
            .eq('store_status', 'delivered'),
      ]);
      if (mounted) {
        final rows = results[0] as List<dynamic>;
        final soldRows = results[1] as List<dynamic>;
        final counts = <String, int>{};
        for (final r in soldRows) {
          final pid = (r as Map)['product_id'] as String?;
          final qty = r['quantity'] as int? ?? 0;
          if (pid != null) counts[pid] = (counts[pid] ?? 0) + qty;
        }
        setState(() {
          _products = rows.map((r) => ProductModel.fromJson(r)).toList();
          _soldCounts = counts;
        });
      }
    } catch (_) {}
  }

  void _onCategoryChanged(String? catId) {
    setState(() => _selectedCategoryId = _selectedCategoryId == catId ? null : catId);
    _loadProducts();
  }

  void _onSortChanged(String? sortBy) {
    if (sortBy == null) return;
    setState(() {
      _sortBy = sortBy;
      _ascending = sortBy == 'base_price';
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.sellerName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildShopHeader(colorScheme)),
                  if (_bestSellers.isNotEmpty)
                    SliverToBoxAdapter(child: _buildBestSellers(colorScheme)),
                  if (_categories.isNotEmpty)
                    SliverToBoxAdapter(child: _buildCategoryFilter(colorScheme)),
                  SliverToBoxAdapter(child: _buildSortRow(colorScheme)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(
                          product: _products[i],
                          soldCount: _soldCounts[_products[i].id],
                          onTap: () => context.pushNamed(
                            'productDetail',
                            pathParameters: {'id': _products[i].id},
                          ),
                        ),
                        childCount: _products.length,
                      ),
                    ),
                  ),
                  if (_products.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined, size: 64, color: colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text('Shop chưa có sản phẩm nào', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildShopHeader(ColorScheme cs) {
    final theme = Theme.of(context);
    final joinedStr = _joinedAt != null ? DateFormat('MM/yyyy').format(_joinedAt!) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.primaryContainer,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? Icon(Icons.store_rounded, size: 30, color: cs.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.sellerName,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: cs.onPrimaryContainer),
                              const SizedBox(width: 3),
                              Text('Shop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statChip(Icons.inventory_2_outlined, '$_productCount sản phẩm', cs),
                        const SizedBox(width: 12),
                        _statChip(Icons.local_fire_department_outlined, 'Đã bán $_totalSold', cs),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_description != null && _description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _description!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (joinedStr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text('Tham gia $joinedStr', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(60)),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.outline),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: cs.outline)),
      ],
    );
  }

  Widget _buildBestSellers(ColorScheme cs) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text('🔥 Bán chạy', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bestSellers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
              final p = _bestSellers[i];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: p,
                  soldCount: _soldCounts[p.id],
                  onTap: () => context.pushNamed('productDetail', pathParameters: {'id': p.id}),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text('📁 Danh mục', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: Text('Tất cả', style: TextStyle(fontSize: 13, color: _selectedCategoryId == null ? cs.onPrimaryContainer : cs.onSurface)),
                selected: _selectedCategoryId == null,
                onSelected: (_) => _onCategoryChanged(null),
                selectedColor: cs.primaryContainer,
                checkmarkColor: cs.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              ...(_categories.map((cat) {
                final catId = cat['id'] as String;
                final catName = cat['name'] as String;
                final isSelected = _selectedCategoryId == catId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(catName, style: TextStyle(fontSize: 13, color: isSelected ? cs.onPrimaryContainer : cs.onSurface)),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(catId),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.onPrimaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              })),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow(ColorScheme cs) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text('${_products.length} sản phẩm', style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              isDense: true,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              items: const [
                DropdownMenuItem(value: 'created_at', child: Text('Mới nhất')),
                DropdownMenuItem(value: 'total_sold', child: Text('Bán chạy')),
                DropdownMenuItem(value: 'base_price', child: Text('Giá thấp')),
                DropdownMenuItem(value: 'average_rating', child: Text('Đánh giá')),
              ],
              onChanged: _onSortChanged,
            ),
          ),
        ],
      ),
    );
  }
}
