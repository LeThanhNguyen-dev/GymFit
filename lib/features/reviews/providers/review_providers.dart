import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseClientProvider));
});

final productReviewsProvider = FutureProvider.family<List<ReviewModel>, String>(
  (ref, productId) =>
      ref.watch(reviewRepositoryProvider).getProductReviews(productId),
);

final reviewSummaryProvider = FutureProvider.family<ReviewSummary, String>(
  (ref, productId) =>
      ref.watch(reviewRepositoryProvider).getReviewSummary(productId),
);

final canReviewProvider = FutureProvider.family<bool, CanReviewArgs>(
  (ref, args) => ref
      .watch(reviewRepositoryProvider)
      .canUserReview(args.userId, args.productId),
);

final createReviewProvider =
    NotifierProvider<CreateReviewNotifier, AsyncValue<ReviewModel?>>(
      CreateReviewNotifier.new,
    );

class CanReviewArgs {
  const CanReviewArgs({required this.userId, required this.productId});

  final String userId;
  final String productId;

  @override
  bool operator ==(Object other) {
    return other is CanReviewArgs &&
        other.userId == userId &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(userId, productId);
}

class CreateReviewNotifier extends Notifier<AsyncValue<ReviewModel?>> {
  late final ReviewRepository _repository = ref.read(reviewRepositoryProvider);

  @override
  AsyncValue<ReviewModel?> build() => const AsyncValue.data(null);

  Future<void> submit({
    required String userId,
    required String productId,
    required String orderItemId,
    required int rating,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.createReview(
        userId: userId,
        productId: productId,
        orderItemId: orderItemId,
        rating: rating,
        comment: comment,
      ),
    );
  }
}
