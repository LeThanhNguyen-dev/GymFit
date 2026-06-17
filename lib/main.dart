import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/providers/core_providers.dart';
import 'core/services/deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
    // TODO: Send to Crashlytics or remote logging here
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error\n$stack');
    // TODO: Send to Crashlytics or remote logging here
    return true;
  };

  await bootstrap();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GymFitApp(),
    ),
  );

  DeepLinkService().init();
}
