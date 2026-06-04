import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymfit/main.dart';

void main() {
  testWidgets('App renders injected home widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(home: Scaffold(body: Text('GymFit smoke test'))),
    );

    expect(find.text('GymFit smoke test'), findsOneWidget);
  });
}
