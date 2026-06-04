import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  const SupabaseStorageService(this._client);

  final SupabaseClient _client;

  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    bool upsert = true,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> remove({
    required String bucket,
    required List<String> paths,
  }) {
    return _client.storage.from(bucket).remove(paths);
  }
}
