import 'package:flutter/material.dart';

import '../widgets/review_list_widget.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, required this.productId, this.userId});

  final String productId;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [ReviewListWidget(productId: productId, userId: userId)],
      ),
    );
  }
}
