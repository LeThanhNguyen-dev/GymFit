import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../../../core/services/supabase_storage_service.dart';
import '../models/profile_model.dart';

const _profileTable = 'profiles';
const _avatarBucket = 'avatars';

class ProfileRepository {
  ProfileRepository(
    this._authService,
    this._databaseService,
    this._storageService,
  );

  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _databaseService;
  final SupabaseStorageService _storageService;

  Future<ProfileModel> getProfile() async {
    final authUser = _authService.currentUser;
    if (authUser == null) throw Exception('Bạn cần đăng nhập trước');

    final rows = await _databaseService
        .table(_profileTable)
        .select()
        .eq('id', authUser.id)
        .limit(1);

    if (rows.isEmpty) throw Exception('Không tìm thấy hồ sơ');
    
    final map = Map<String, dynamic>.from(rows.first);
    var role = map['role']?.toString() ?? 'customer';
    var sellerStatus = map['seller_status']?.toString() ?? 'none';

    if (role == 'customer' || sellerStatus != 'approved') {
      try {
        final regRows = await _databaseService
            .table('shop_registrations')
            .select('status')
            .eq('user_id', authUser.id)
            .eq('status', 'approved')
            .limit(1);
        if (regRows.isNotEmpty) {
          map['role'] = 'storeowner';
          map['seller_status'] = 'approved';
        }
      } catch (_) {}
    }

    return ProfileModel.fromJson(map);
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    if (_authService.currentUser == null) {
      throw Exception('Bạn cần đăng nhập trước');
    }

    final updated = await guardSupabase(
      () => _databaseService.updateById(
        _profileTable,
        profile.id,
        profile.toUpdateJson(),
      ),
    );
    return ProfileModel.fromJson(updated);
  }

  Future<String?> uploadAvatar(XFile file) async {
    final authUser = _authService.currentUser;
    if (authUser == null) throw Exception('Bạn cần đăng nhập trước');

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final path = '${authUser.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final contentType = switch (ext.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final url = await _storageService.uploadBytes(
      bucket: _avatarBucket,
      path: path,
      bytes: bytes,
      contentType: contentType,
    );

    await _databaseService.upsert(
      _profileTable,
      {
        'id': authUser.id,
        'email': authUser.email ?? '',
        'avatar_url': url,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );

    return url;
  }
}
