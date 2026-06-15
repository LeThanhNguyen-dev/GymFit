import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../data/repositories/ai_recommendation_repository.dart';

final aiRecommendationRepositoryProvider = Provider<AIRecommendationRepository>(
  (ref) {
    return AIRecommendationRepository(ref.watch(supabaseClientProvider));
  },
);

final similarProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, productId) {
      return ref
          .watch(aiRecommendationRepositoryProvider)
          .getSimilarProducts(productId);
    });

final alsoBoughtProvider = FutureProvider.family<List<ProductModel>, String>((
  ref,
  productId,
) {
  return ref
      .watch(aiRecommendationRepositoryProvider)
      .getAlsoBoughtProducts(productId);
});

final personalizedProvider = FutureProvider<List<ProductModel>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return ref.watch(aiRecommendationRepositoryProvider).getTrendingProducts();
  }
  return ref
      .watch(aiRecommendationRepositoryProvider)
      .getPersonalizedRecommendations(userId);
});
