import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (AppConstants.supabaseUrl.isNotEmpty &&
        AppConstants.supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    } else {
      debugPrint('⚠️ SUPABASE_URL hoặc SUPABASE_ANON_KEY trống — dùng MockAuthRepository');
    }
  } catch (e) {
    debugPrint('⚠️ Supabase init thất bại: $e — dùng MockAuthRepository');
  }
}
