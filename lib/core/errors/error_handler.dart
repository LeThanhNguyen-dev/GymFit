import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../exceptions/app_exception.dart';

AppException handleSupabaseError(Object error) {
  if (error is supabase.PostgrestException) {
    return ServerException(
      error.message,
      code: error.code,
      originalError: error,
    );
  }

  if (error is supabase.AuthException) {
    return AuthException(
      error.message,
      code: error.statusCode.toString(),
      originalError: error,
    );
  }

  if (error is supabase.StorageException) {
    return ServerException(
      error.message,
      code: error.statusCode.toString(),
      originalError: error,
    );
  }

  if (error is AppException) {
    return error;
  }

  return AppException(
    error.toString(),
    originalError: error,
  );
}

Future<T> guardSupabase<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (e) {
    throw handleSupabaseError(e);
  }
}
