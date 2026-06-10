import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/review_model.dart';
import '../../providers/review_providers.dart';
import 'review_card.dart';

class ReviewListWidget extends ConsumerWidget {
  const ReviewListWidget({
    super.key,
    required this.productId,
    this.userId,
    this.onWriteReview,
  });

  final String productId;
  final String? userId;
  final VoidCallback? onWriteReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reviewSummaryProvider(productId));
    final reviews = ref.watch(productReviewsProvider(productId));
    final canReview = userId == null
        ? const AsyncValue.data(false)
        : ref.watch(
            canReviewProvider(
              CanReviewArgs(userId: userId!, productId: productId),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary.when(
          data: (data) => _Summary(summary: data),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              Text('Could not load rating summary: $error'),
        ),
        const SizedBox(height: 12),
        canReview.when(
          data: (allowed) => allowed
              ? FilledButton.icon(
                  onPressed: onWriteReview,
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Write review'),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        reviews.when(
          data: (items) {
            if (items.isEmpty) return const Text('No reviews yet.');
            return Column(
              children: [
                ...items.map((review) => ReviewCard(review: review)),
                TextButton(onPressed: () {}, child: const Text('See more')),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Could not load reviews: $error'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.avgRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text('${summary.totalReviews} reviews'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = summary.distribution[star] ?? 0;
              final value = summary.totalReviews == 0
                  ? 0.0
                  : count / summary.totalReviews;
              return Row(
                children: [
                  SizedBox(width: 32, child: Text('$star star')),
                  Expanded(child: LinearProgressIndicator(value: value)),
                  SizedBox(
                    width: 32,
                    child: Text(count.toString(), textAlign: TextAlign.end),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
