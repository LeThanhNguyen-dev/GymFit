import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always try to initialize Supabase so Supabase.instance.client doesn't crash
  try {
    if (AppConstants.supabaseUrl.isNotEmpty &&
        AppConstants.supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    }
  } catch (_) {
    // Supabase unreachable — mock mode will handle fallback
  }
}
