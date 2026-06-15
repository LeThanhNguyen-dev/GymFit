import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymfit/app/app.dart';
import 'package:gymfit/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:gymfit/features/auth/providers/auth_providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const GymFitApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
