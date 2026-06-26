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
              Text('Không thể tải đánh giá: $error'),
        ),
        const SizedBox(height: 12),
        canReview.when(
          data: (allowed) => allowed
              ? FilledButton.icon(
                  onPressed: onWriteReview,
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Viết đánh giá'),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        reviews.when(
          data: (items) {
            if (items.isEmpty) return const Text('Chưa có đánh giá.');
            return Column(
              children: [
                ...items.map((review) => ReviewCard(review: review)),
                TextButton(onPressed: () {}, child: const Text('Xem thêm')),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Không thể tải đánh giá: $error'),
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
              Row(
                children: [
                  Text(
                    summary.avgRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: Colors.amber[600], size: 22),
                ],
              ),
              Text(
                '${summary.totalReviews} đánh giá',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = summary.distribution[star] ?? 0;
              final value = summary.totalReviews == 0
                  ? 0.0
                  : count / summary.totalReviews;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 24,
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
