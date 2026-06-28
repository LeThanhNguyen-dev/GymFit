import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';
import '../services/product_cache_service.dart';

final productCacheServiceProvider = Provider<ProductCacheService>((ref) {
  return ProductCacheService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(connectivityProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseClientProvider));
});

final storeProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];
  return repo.getStoreProducts(sellerId: userId);
});

final featuredProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final cacheService = ref.watch(productCacheServiceProvider);
  
  if (await cacheService.isOffline()) {
    final cached = cacheService.getFeatured();
    if (cached != null) return cached;
  }
  
  final products = await repo.getFeaturedProducts(limit: 10);
  await cacheService.saveFeatured(products);
  return products;
});

final bestSellersProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getBestSellers(limit: 10);
});

final newArrivalsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final cacheService = ref.watch(productCacheServiceProvider);
  
  if (await cacheService.isOffline()) {
    final cached = cacheService.getNewArrivals();
    if (cached != null) return cached;
  }

  final products = await repo.getNewArrivals(limit: 10);
  await cacheService.saveNewArrivals(products);
  return products;
});

final recommendedProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final cacheService = ref.watch(productCacheServiceProvider);
  
  if (await cacheService.isOffline()) {
    final cached = cacheService.getRecommended();
    if (cached != null) return cached;
  }

  final products = await repo.getRecommendedProducts(limit: 10);
  await cacheService.saveRecommended(products);
  return products;
});

final flashSaleProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final products = await repo.getFeaturedProducts(limit: 20);
  final onSale = products.where((p) =>
    p.compareAtPrice != null &&
    p.compareAtPrice! > p.basePrice &&
    p.status == ProductStatus.active
  ).toList();
  onSale.sort((a, b) => ((b.compareAtPrice! - b.basePrice) / b.compareAtPrice! * 100)
      .compareTo(((a.compareAtPrice! - a.basePrice) / a.compareAtPrice! * 100)));
  return onSale.take(8).toList();
});

final recommendedMoreProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getRecommendedProducts(limit: 20);
});

final productDetailProvider = FutureProvider.family
    .autoDispose<ProductModel?, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(id);
});

class RelatedProductsArgs {
  const RelatedProductsArgs({
    required this.productId,
    required this.categoryId,
  });
  final String productId;
  final String categoryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelatedProductsArgs &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          categoryId == other.categoryId;

  @override
  int get hashCode => productId.hashCode ^ categoryId.hashCode;
}

final relatedProductsProvider = FutureProvider.family
    .autoDispose<List<ProductModel>, RelatedProductsArgs>((ref, args) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getRelatedProducts(args.productId, args.categoryId, limit: 6);
});

// ── Product List State ─────────────────────────────────────────────────────────

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadMoreRunning = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.ascending = true,
    this.searchQuery,
  });

  final List<ProductModel> products;
  final bool isLoading;
  final bool isLoadMoreRunning;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final String? categoryId;
  final String? brandId;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final bool ascending;
  final String? searchQuery;

  ProductListState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? isLoadMoreRunning,
    String? Function()? errorMessage,
    int? page,
    bool? hasMore,
    String? Function()? categoryId,
    String? Function()? brandId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    String? Function()? sortBy,
    bool? ascending,
    String? Function()? searchQuery,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreRunning: isLoadMoreRunning ?? this.isLoadMoreRunning,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      brandId: brandId != null ? brandId() : this.brandId,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      sortBy: sortBy != null ? sortBy() : this.sortBy,
      ascending: ascending ?? this.ascending,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
    );
  }
}

// ── Product List Notifier (Riverpod 3.x) ──────────────────────────────────────

class ProductListNotifier extends Notifier<ProductListState> {
  static const int _pageSize = 20;

  @override
  ProductListState build() {
    Future.delayed(Duration.zero, loadProducts);
    return const ProductListState();
  }

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  Future<void> loadProducts() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      page: 1,
      hasMore: true,
    );
    try {
      final items = await _repository.getProducts(
        page: 1,
        pageSize: _pageSize,
        categoryId: state.categoryId,
        brandId: state.brandId,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        sortBy: state.sortBy,
        ascending: state.ascending,
        search: state.searchQuery,
      );
      state = state.copyWith(
        products: items,
        isLoading: false,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadMoreRunning || !state.hasMore) return;
    state = state.copyWith(isLoadMoreRunning: true);
    final nextPage = state.page + 1;
    try {
      final items = await _repository.getProducts(
        page: nextPage,
        pageSize: _pageSize,
        categoryId: state.categoryId,
        brandId: state.brandId,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        sortBy: state.sortBy,
        ascending: state.ascending,
        search: state.searchQuery,
      );
      state = state.copyWith(
        products: [...state.products, ...items],
        page: nextPage,
        isLoadMoreRunning: false,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadMoreRunning: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void updateCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
    loadProducts();
  }

  void updateBrand(String? brandId) {
    state = state.copyWith(brandId: () => brandId);
    loadProducts();
  }

  void updatePriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(
      minPrice: () => minPrice,
      maxPrice: () => maxPrice,
    );
    loadProducts();
  }

  void updateSort(String? sortBy, bool ascending) {
    state = state.copyWith(sortBy: () => sortBy, ascending: ascending);
    loadProducts();
  }

  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: () => query);
    loadProducts();
  }

  void clearFilters() {
    state = state.copyWith(
      categoryId: () => null,
      brandId: () => null,
      minPrice: () => null,
      maxPrice: () => null,
      sortBy: () => null,
      ascending: true,
      searchQuery: () => null,
    );
    loadProducts();
  }
}

final productListProvider =
    NotifierProvider.autoDispose<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);
