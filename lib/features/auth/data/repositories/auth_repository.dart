import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../models/auth_model.dart';

abstract class IAuthRepository {
  Future<AuthResult> login(LoginRequest request);
  Future<AuthResult> register(RegisterRequest request);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<AuthResult> confirmEmail(String email);
  Future<AuthResult> verifyResetToken(String token);
  Future<void> updatePassword(String newPassword);
  AppUser? get currentUser;
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
      final user = response.user;
      if (user == null) {
        return const AuthResultError('Không tìm thấy tài khoản');
      }

      final fullName = user.userMetadata?['full_name']?.toString();
      await _upsertUserProfile(
        id: user.id,
        email: user.email ?? request.email,
        fullName: fullName,
      );

      return AuthResultSuccess(
        AppUser(id: user.id, email: user.email ?? '', fullName: fullName),
      );
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

      final user = response.user;
      if (user == null) {
        return const AuthResultError('Đăng ký thất bại');
      }

      if (response.session == null) {
        return AuthResultNeedsVerification(
          AppUser(
            id: user.id,
            email: user.email ?? request.email,
            fullName: request.fullName,
          ),
          user.email ?? request.email,
        );
      }

      await _upsertUserProfile(
        id: user.id,
        email: user.email ?? request.email,
        fullName: request.fullName,
      );

      await _authService.signOut();
      return AuthResultSuccess(
        AppUser(
          id: user.id,
          email: user.email ?? request.email,
          fullName: request.fullName,
        ),
      );
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
  AppUser? get currentUser {
    final user = _authService.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name']?.toString(),
    );
  }

  Future<void> _upsertUserProfile({
    required String id,
    required String email,
    String? fullName,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final trimmedName = fullName?.trim();

    return _databaseService.table(AppConstants.usersTable).upsert({
      'id': id,
      'email': email,
      'full_name': trimmedName == null || trimmedName.isEmpty
          ? null
          : trimmedName,
      'last_login_at': now,
      'updated_at': now,
    });
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
