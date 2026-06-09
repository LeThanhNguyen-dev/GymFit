import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/models/auth_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (AppConstants.useMockAuth) {
    return MockAuthRepository();
  }
  return AuthRepository(ref.watch(supabaseAuthServiceProvider));
});

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthStateData {
  const AuthStateData({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.isLoading = false,
    this.emailForVerification,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool isLoading;
  final String? emailForVerification;

  AuthStateData copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? isLoading,
    String? emailForVerification,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      emailForVerification: emailForVerification,
    );
  }
}

class AuthNotifier extends Notifier<AuthStateData> {
  @override
  AuthStateData build() {
    _checkCurrentUser();
    return const AuthStateData(status: AuthStatus.uninitialized);
  }

  void _checkCurrentUser() {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      state = AuthStateData(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = const AuthStateData(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(authRepositoryProvider).login(
      LoginRequest(email: email, password: password),
    );

    result.when(
      success: (user) {
        state = AuthStateData(status: AuthStatus.authenticated, user: user);
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư đến của $email',
          emailForVerification: email,
        );
      },
      error: (message) {
        state = state.copyWith(isLoading: false, error: message);
      },
      needsVerification: (_, _) {
        state = state.copyWith(isLoading: false, error: 'Đăng nhập thất bại');
      },
    );
  }

  Future<void> register(String email, String password, {String? fullName}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(authRepositoryProvider).register(
      RegisterRequest(email: email, password: password, fullName: fullName),
    );

    result.when(
      success: (user) {
        state = AuthStateData(status: AuthStatus.authenticated, user: user);
      },
      needsVerification: (user, email) {
        state = AuthStateData(
          status: AuthStatus.unauthenticated,
          user: user,
          emailForVerification: email,
        );
      },
      error: (message) {
        state = state.copyWith(isLoading: false, error: message);
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email chưa được xác thực',
          emailForVerification: email,
        );
      },
    );
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: null,
        emailForVerification: email,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null, emailForVerification: null);
  }

  void resendVerification() {
    final email = state.emailForVerification;
    if (email != null) {
      state = state.copyWith(
        error: 'Email xác thực đã được gửi lại tới $email',
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);
