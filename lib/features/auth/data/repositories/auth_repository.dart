import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../models/auth_model.dart';

const _profileTable = 'profiles';

abstract class IAuthRepository {
  Future<AuthResult> login(LoginRequest request);
  Future<AuthResult> register(RegisterRequest request);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resendVerificationEmail(String email);
  Future<AuthResult> confirmEmail(String email);
  Future<AuthResult> verifyResetToken(String token);
  Future<void> updatePassword(String newPassword);
  Future<void> requestSeller();
  AppUser? get currentUser;
  Future<AppUser?> fetchProfile();
}

class AuthRepository implements IAuthRepository {
  AuthRepository(this._authService, this._databaseService);

  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _databaseService;

  @override
  Future<AuthResult> login(LoginRequest request) async {
    try {
      final response = await _authService.signInWithPassword(
        email: request.email,
        password: request.password,
      );
      final authUser = response.user;
      if (authUser == null) {
        return const AuthResultError('Không tìm thấy tài khoản');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final profile = await _ensureProfile(
        id: authUser.id,
        email: authUser.email ?? request.email,
        fullName: authUser.userMetadata?['full_name']?.toString(),
        lastLoginAt: now,
        updatedAt: now,
      );

      return AuthResultSuccess(AppUser(
        id: authUser.id,
        email: authUser.email ?? request.email,
        fullName: profile['full_name']?.toString(),
        role: profile['role']?.toString() ?? 'customer',
        sellerStatus: profile['seller_status']?.toString() ?? 'none',
      ));
    } catch (e) {
      final message = _parseAuthError(e);
      if (message.contains('chưa được xác thực')) {
        return AuthResultEmailNotConfirmed(request.email);
      }
      return AuthResultError(message);
    }
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    try {
      final response = await _authService.signUp(
        email: request.email,
        password: request.password,
        data: {
          if (request.fullName != null) 'full_name': request.fullName,
        },
        emailRedirectTo: 'gymfit://auth-callback',
      );

      final authUser = response.user;
      if (authUser == null) {
        return const AuthResultError('Đăng ký thất bại');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      try {
        await _databaseService.upsert(_profileTable, {
          'id': authUser.id,
          'email': authUser.email ?? request.email,
          if (request.fullName != null) 'full_name': request.fullName,
          'role': 'customer',
          'seller_status': 'none',
          'created_at': now,
          'updated_at': now,
        }, onConflict: 'id');
      } catch (_) {
        // profile creation may fail (RLS), first login will ensure it exists
      }

      if (response.session == null) {
        return AuthResultNeedsVerification(
          AppUser(
            id: authUser.id,
            email: authUser.email ?? request.email,
            fullName: request.fullName,
            role: 'customer',
            sellerStatus: 'none',
          ),
          authUser.email ?? request.email,
        );
      }

      await _authService.signOut();
      return AuthResultSuccess(AppUser(
        id: authUser.id,
        email: authUser.email ?? request.email,
        fullName: request.fullName,
        role: 'customer',
        sellerStatus: 'none',
      ));
    } catch (e) {
      return AuthResultError(_parseAuthError(e));
    }
  }

  @override
  Future<void> logout() async {
    await guardSupabase(() => _authService.signOut());
  }

  @override
  Future<void> forgotPassword(String email) async {
    await guardSupabase(
      () => _authService.resetPasswordForEmail(
        email,
        redirectTo: 'gymfit://reset-password',
      ),
    );
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    await guardSupabase(
      () => _authService.resendVerificationEmail(email),
    );
  }

  @override
  Future<AuthResult> confirmEmail(String email) async {
    try {
      if (_authService.currentUser?.emailConfirmedAt != null) {
        return AuthResultSuccess(
          AppUser(id: _authService.currentUser!.id, email: email),
        );
      }
      return AuthResultSuccess(AppUser(id: '', email: email));
    } catch (_) {
      return AuthResultSuccess(AppUser(id: '', email: email));
    }
  }

  @override
  Future<AuthResult> verifyResetToken(String token) async {
    return AuthResultSuccess(AppUser(id: '', email: ''));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await guardSupabase(() => _authService.updatePassword(newPassword));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('session') || msg.contains('not authenticated') || msg.contains('Auth session missing')) {
        throw Exception('Phiên đặt lại mật khẩu không hợp lệ. Vui lòng mở lại link trong email và thử lại.');
      }
      rethrow;
    }
  }

  @override
  Future<void> requestSeller() async {
    final authUser = _authService.currentUser;
    if (authUser == null) throw Exception('Bạn cần đăng nhập trước');
    final now = DateTime.now().toUtc().toIso8601String();
    await guardSupabase(() => _databaseService.upsert(_profileTable, {
      'id': authUser.id,
      'email': authUser.email ?? '',
      'seller_status': 'pending',
      'updated_at': now,
    }, onConflict: 'id'));
  }

  @override
  AppUser? get currentUser {
    final authUser = _authService.currentUser;
    if (authUser == null) return null;
    return AppUser(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: authUser.userMetadata?['full_name']?.toString(),
    );
  }

  @override
  Future<AppUser?> fetchProfile() async {
    final authUser = _authService.currentUser;
    if (authUser == null) return null;
    try {
      final rows = await _databaseService
          .table(_profileTable)
          .select()
          .eq('id', authUser.id)
          .limit(1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        return AppUser(
          id: authUser.id,
          email: row['email']?.toString() ?? authUser.email ?? '',
          fullName: row['full_name']?.toString(),
          role: row['role']?.toString() ?? 'customer',
          sellerStatus: row['seller_status']?.toString() ?? 'none',
        );
      }
    } catch (_) {}
    final metadata = {...?authUser.appMetadata, ...?authUser.userMetadata};
    return AppUser(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: authUser.userMetadata?['full_name'] as String?,
      role: metadata['role'] as String? ?? 'customer',
      sellerStatus: metadata['seller_status'] as String? ?? 'none',
    );
  }

  Future<Map<String, dynamic>> _ensureProfile({
    required String id,
    required String email,
    String? fullName,
    String? lastLoginAt,
    String? updatedAt,
  }) async {
    try {
      final rows = await _databaseService
          .table(_profileTable)
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isNotEmpty) {
        final existing = Map<String, dynamic>.from(rows.first);
        final now = DateTime.now().toUtc().toIso8601String();
        await _databaseService.upsert(_profileTable, {
          'id': id,
          'email': email,
          'last_login_at': lastLoginAt ?? now,
          'updated_at': updatedAt ?? now,
        }, onConflict: 'id');
        return existing;
      }
    } catch (_) {}

    final now = DateTime.now().toUtc().toIso8601String();
    await _databaseService.upsert(_profileTable, {
      'id': id,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      'role': 'customer',
      'seller_status': 'none',
      'last_login_at': lastLoginAt ?? now,
      'created_at': now,
      'updated_at': updatedAt ?? now,
    }, onConflict: 'id');

    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': 'customer',
      'seller_status': 'none',
    };
  }

  String _parseAuthError(Object error) {
    final msg = error.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (msg.contains('Email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.';
    }
    if (msg.contains('User already registered')) {
      return 'Email này đã được đăng ký';
    }
    if (msg.contains('Rate limit')) {
      return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
    }
    if (msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('No address')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
    }
    return msg
        .replaceFirst('Exception: ', '')
        .replaceFirst('AuthException: ', '');
  }
}

sealed class AuthResult {
  const AuthResult();

  T when<T>({
    required T Function(AppUser user) success,
    required T Function(String message) error,
    required T Function(String email) emailNotConfirmed,
    required T Function(AppUser user, String email) needsVerification,
  }) {
    return switch (this) {
      final AuthResultSuccess s => success(s.user),
      final AuthResultError e => error(e.message),
      final AuthResultEmailNotConfirmed e => emailNotConfirmed(e.email),
      final AuthResultNeedsVerification n => needsVerification(n.user, n.email),
    };
  }
}

class AuthResultSuccess extends AuthResult {
  const AuthResultSuccess(this.user);
  final AppUser user;
}

class AuthResultError extends AuthResult {
  const AuthResultError(this.message);
  final String message;
}

class AuthResultEmailNotConfirmed extends AuthResult {
  const AuthResultEmailNotConfirmed(this.email);
  final String email;
}

class AuthResultNeedsVerification extends AuthResult {
  const AuthResultNeedsVerification(this.user, this.email);
  final AppUser user;
  final String email;
}
