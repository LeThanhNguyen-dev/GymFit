import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reviews/data/models/review_model.dart';
import '../../reviews/providers/review_providers.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(reviewRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage reviews')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'flagged', child: Text('Flagged')),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReviewModel>>(
              future: repository.getAdminReviews(status: _status),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data!;
                if (reviews.isEmpty) {
                  return const Center(child: Text('No reviews.'));
                }
                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ListTile(
                      title: Text(
                        '${review.rating}/5 - ${review.user?.fullName ?? review.userId}',
                      ),
                      subtitle: Text(
                        review.comment ?? 'No comment',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (status) async {
                          await repository.updateReviewStatus(
                            review.id,
                            status,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'approved',
                            child: Text('Approve'),
                          ),
                          PopupMenuItem(
                            value: 'rejected',
                            child: Text('Reject'),
                          ),
                          PopupMenuItem(value: 'flagged', child: Text('Flag')),
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
    );
  }
}
