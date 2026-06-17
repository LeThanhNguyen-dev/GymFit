import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';

class ComparisonNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => [];

  static const int maxProducts = 3;

  bool addProduct(ProductModel product) {
    if (state.length >= maxProducts) return false;
    if (state.any((p) => p.id == product.id)) return false;
    
    state = [...state, product];
    return true;
  }

  void removeProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void clear() {
    state = [];
  }

  bool isComparing(String productId) {
    return state.any((p) => p.id == productId);
  }
}

final comparisonProvider =
    NotifierProvider<ComparisonNotifier, List<ProductModel>>(ComparisonNotifier.new);
