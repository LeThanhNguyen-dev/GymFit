import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/sort_dropdown.dart';
import '../../reviews/providers/review_providers.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  final _searchController = TextEditingController();
  String? _status;
  int? _rating;
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(reviewRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage reviews')),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildSortRow(),
          Expanded(
            child: FutureBuilder(
              future: repository.getAdminReviews(
                status: _status,
                rating: _rating,
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                sortBy: _sortBy,
                ascending: _ascending,
                page: _page,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final result = snapshot.data!;
                final reviews = result.items;
                if (reviews.isEmpty) {
                  return const Center(child: Text('No reviews.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
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
                            if (mounted) setState(() {});
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
                  ),
                );
              },
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search in comments',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onFilterChanged(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('All', null, _status),
                const SizedBox(width: 8),
                _buildChip('Pending', 'pending', _status),
                const SizedBox(width: 8),
                _buildChip('Approved', 'approved', _status),
                const SizedBox(width: 8),
                _buildChip('Rejected', 'rejected', _status),
                const SizedBox(width: 8),
                _buildChip('Flagged', 'flagged', _status),
                const SizedBox(width: 16),
                _buildChip('All stars', null, _rating),
                const SizedBox(width: 8),
                _buildChip('5★', 5, _rating),
                const SizedBox(width: 8),
                _buildChip('4★', 4, _rating),
                const SizedBox(width: 8),
                _buildChip('3★', 3, _rating),
                const SizedBox(width: 8),
                _buildChip('2★', 2, _rating),
                const SizedBox(width: 8),
                _buildChip('1★', 1, _rating),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Object? value, Object? currentValue) {
    final selected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (value is String?) {
            _status = selected ? null : value;
          } else if (value is int?) {
            _rating = selected ? null : (value as int?);
          } else {
            _status = null;
            _rating = null;
          }
          _page = 1;
        });
      },
    );
  }

  Widget _buildSortRow() {
    const sortOptions = [
      SortOption('created_at_desc', 'Mới nhất'),
      SortOption('created_at', 'Cũ nhất'),
      SortOption('rating', 'Rating low-high'),
      SortOption('rating_desc', 'Rating high-low'),
    ];
    final currentKey = _ascending ? _sortBy : '${_sortBy}_desc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SortDropdown(
        value: currentKey,
        options: sortOptions,
        onChanged: (key) {
          setState(() {
            if (key.endsWith('_desc')) {
              _sortBy = key.replaceAll('_desc', '');
              _ascending = false;
            } else {
              _sortBy = key;
              _ascending = true;
            }
            _page = 1;
          });
        },
      ),
    );
  }

  Widget _buildPagination() {
    return FutureBuilder(
      future: ref.read(reviewRepositoryProvider).getAdminReviews(
        status: _status,
        rating: _rating,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sortBy: _sortBy,
        ascending: _ascending,
        page: _page,
        pageSize: 20,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        final totalPages = (result.totalCount / 20).ceil();
        return PaginationBar(
          page: _page,
          totalPages: totalPages,
          totalItems: result.totalCount,
          onPageChanged: (p) => setState(() => _page = p),
        );
      },
    );
  }
}
