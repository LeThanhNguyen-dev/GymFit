import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/services/deep_link_service.dart';
import '../data/models/auth_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (AppConstants.useMockAuth) {
    return MockAuthRepository();
  }
  return AuthRepository(
    ref.watch(supabaseAuthServiceProvider),
    ref.watch(supabaseDatabaseServiceProvider),
  );
});

enum AuthStatus { uninitialized, authenticated, unauthenticated, emailVerification, resetSent }

class AuthStateData {
  const AuthStateData({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.successMessage,
    this.isLoading = false,
    this.emailForVerification,
    this.verificationSuccess = false,
    this.resetSuccess = false,
    this.resetToken,
    this.resendCooldown = 0,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final String? successMessage;
  final bool isLoading;
  final String? emailForVerification;
  final bool verificationSuccess;
  final bool resetSuccess;
  final String? resetToken;
  final int resendCooldown;

  AuthStateData copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    String? successMessage,
    bool? isLoading,
    String? emailForVerification,
    bool? verificationSuccess,
    bool? resetSuccess,
    String? resetToken,
    int? resendCooldown,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      successMessage: successMessage,
      isLoading: isLoading ?? this.isLoading,
      emailForVerification: emailForVerification ?? this.emailForVerification,
      verificationSuccess: verificationSuccess ?? this.verificationSuccess,
      resetSuccess: resetSuccess ?? this.resetSuccess,
      resetToken: resetToken ?? this.resetToken,
      resendCooldown: resendCooldown ?? this.resendCooldown,
    );
  }
}

class AuthNotifier extends Notifier<AuthStateData> {
  StreamSubscription? _authSub;
  StreamSubscription? _deepLinkSub;
  String? _pendingAction;
  Timer? _verificationTimer;
  Timer? _cooldownTimer;

  @override
  AuthStateData build() {
    if (!AppConstants.useMockAuth) {
      _setupDeepLinkListener();
      _setupAuthListener();
    }
    Future.microtask(() => _checkCurrentUser());
    ref.onDispose(() {
      _authSub?.cancel();
      _deepLinkSub?.cancel();
      _verificationTimer?.cancel();
      _cooldownTimer?.cancel();
    });
    return const AuthStateData(status: AuthStatus.unauthenticated);
  }

  void _setupDeepLinkListener() {
    try {
      _deepLinkSub = DeepLinkService().onDeepLink.listen((action) {
        if (action == 'reset') {
          proceedToReset();
        } else {
          _pendingAction = action;
        }
      });
    } catch (_) {}
  }

  void _setupAuthListener() {
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          _onSignedIn();
        } else if (event.event == AuthChangeEvent.passwordRecovery) {
          proceedToReset();
        }
      });
    } catch (_) {}
  }

  void _onSignedIn() {
    final action = _pendingAction;
    _pendingAction = null;

    if (action == 'verify') {
      _handleVerifySuccess();
    } else if (state.status == AuthStatus.emailVerification) {
      _handleVerifySuccess();
    }
  }

  Future<void> _handleVerifySuccess() async {
    _verificationTimer?.cancel();
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    state = AuthStateData(
      status: AuthStatus.unauthenticated,
      verificationSuccess: true,
    );
  }

  Future<void> _checkCurrentUser() async {
    if (_pendingAction != null) return;
    if (state.resetToken != null) return;
    try {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        AppUser? user;
        try {
          user = await ref.read(authRepositoryProvider).fetchProfile();
        } catch (_) {}
        state = AuthStateData(
          status: AuthStatus.authenticated,
          user: user ?? AppUser(
            id: supabaseUser.id,
            email: supabaseUser.email ?? '',
            fullName: supabaseUser.userMetadata?['full_name'] as String?,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref
        .read(authRepositoryProvider)
        .login(LoginRequest(email: email, password: password));

    result.when(
      success: (user) {
        state = AuthStateData(status: AuthStatus.authenticated, user: user);
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email chưa được xác thực. Vui lòng xác thực email trước khi đăng nhập.',
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

  Future<void> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref
        .read(authRepositoryProvider)
        .register(
          RegisterRequest(email: email, password: password, fullName: fullName),
        );

    result.when(
      success: (user) {
        state = const AuthStateData(
          status: AuthStatus.unauthenticated,
          successMessage: 'Đăng ký thành công. Vui lòng đăng nhập.',
        );
      },
      needsVerification: (user, email) {
        _startVerificationCheck(email, password);
        state = AuthStateData(
          status: AuthStatus.emailVerification,
          user: user,
          emailForVerification: email,
          successMessage:
              'Đăng ký thành công. Vui lòng kiểm tra email xác thực rồi đăng nhập.',
        );
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await ref.read(authRepositoryProvider).resendVerificationEmail(email);
          } catch (_) {}
        });
      },
      error: (message) {
        state = state.copyWith(isLoading: false, error: message);
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(isLoading: false, error: 'Email đã tồn tại', emailForVerification: email);
      },
    );
  }

  Future<void> confirmEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(authRepositoryProvider).confirmEmail(email);

    result.when(
      success: (_) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          verificationSuccess: true,
          emailForVerification: email,
        );
      },
      error: (message) {
        state = state.copyWith(isLoading: false, error: message);
      },
      needsVerification: (_, _) {
        state = state.copyWith(isLoading: false, error: 'Xác thực thất bại');
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(isLoading: false, error: 'Xác thực thất bại', emailForVerification: email);
      },
    );
  }

  Future<void> resendVerification(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail(email);
    } catch (_) {
      state = state.copyWith(error: 'Gửi email thất bại. Vui lòng thử lại.');
      return;
    }
    _startCooldown();
  }

  void _startCooldown() {
    state = state.copyWith(resendCooldown: 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendCooldown - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: remaining);
      }
    });
  }

  void _startVerificationCheck(String email, String password) {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final result = await ref.read(authRepositoryProvider).login(
          LoginRequest(email: email, password: password),
        );
        result.when(
          success: (_) {
            _verificationTimer?.cancel();
            _handleVerifySuccess();
          },
          error: (_) {},
          emailNotConfirmed: (_) {},
          needsVerification: (_, _) {},
        );
      } catch (_) {}
    });
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      state = state.copyWith(
        status: AuthStatus.resetSent,
        isLoading: false,
        emailForVerification: email,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> verifyResetToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(authRepositoryProvider).verifyResetToken(token);

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, resetToken: token);
      },
      error: (message) {
        state = state.copyWith(isLoading: false, error: message);
      },
      needsVerification: (_, _) {
        state = state.copyWith(isLoading: false, error: 'Token không hợp lệ');
      },
      emailNotConfirmed: (email) {
        state = state.copyWith(isLoading: false, error: 'Token không hợp lệ');
      },
    );
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      await ref.read(authRepositoryProvider).logout();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        resetSuccess: true,
        error: null,
        resetToken: null,
      );
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

  Future<void> requestSeller() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).requestSeller();
      final updated = await ref.read(authRepositoryProvider).fetchProfile();
      if (updated != null) {
        state = AuthStateData(status: AuthStatus.authenticated, user: updated);
      } else {
        state = state.copyWith(isLoading: false, successMessage: 'Yêu cầu đã được gửi');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetToLogin() {
    _verificationTimer?.cancel();
    state = const AuthStateData(status: AuthStatus.unauthenticated);
  }

  void proceedToReset() {
    state = state.copyWith(resetToken: 'recovery', status: AuthStatus.unauthenticated);
  }


}

final authProvider = NotifierProvider<AuthNotifier, AuthStateData>(
  AuthNotifier.new,
);

final requestSellerProvider = Provider<void Function()>((ref) {
  return () => ref.read(authProvider.notifier).requestSeller();
});
