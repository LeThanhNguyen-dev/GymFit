import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../providers/review_providers.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.productId,
    required this.orderId,
    required this.productName,
    this.productImageUrl,
  });

  final String productId;
  final String orderId;
  final String productName;
  final String? productImageUrl;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Write review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (widget.productImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.productImageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const SizedBox.square(dimension: 64, child: Icon(Icons.image)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                icon: Icon(value <= _rating ? Icons.star : Icons.star_border),
                color: Colors.amber.shade700,
              );
            }),
          ),
          TextField(
            controller: _commentController,
            minLines: 4,
            maxLines: 8,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Comment optional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add photos unavailable'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: createState.isLoading ? null : _submit,
            child: createState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit review'),
          ),
          createState.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Could not submit review: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a rating.')));
      return;
    }
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    await ref
        .read(createReviewProvider.notifier)
        .submit(
          userId: userId,
          productId: widget.productId,
          orderId: widget.orderId,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
    if (!mounted) return;
    ref.invalidate(productReviewsProvider(widget.productId));
    ref.invalidate(reviewSummaryProvider(widget.productId));
    Navigator.of(context).pop();
  }
}
