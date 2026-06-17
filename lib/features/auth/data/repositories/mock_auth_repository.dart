import 'dart:math';

import '../models/auth_model.dart';
import 'auth_repository.dart';

class _MockUser {
  const _MockUser({
    required this.email,
    required this.password,
    this.fullName,
    this.confirmed = false,
  });
  final String email;
  final String password;
  final String? fullName;
  final bool confirmed;

  _MockUser copyWith({bool? confirmed, String? password}) {
    return _MockUser(
      email: email,
      password: password ?? this.password,
      fullName: fullName,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

class MockAuthRepository implements IAuthRepository {
  final _users = <_MockUser>[];
  final _resetTokens = <String, String>{};
  _MockUser? _currentUser;
  int _nextId = 1;

  @override
  Future<AuthResult> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _users.cast<_MockUser?>().firstWhere(
      (u) => u!.email == request.email,
      orElse: () => null,
    );

    if (user == null) {
      return AuthResultError('Email hoặc mật khẩu không đúng');
    }

    if (user.password != request.password) {
      return AuthResultError('Email hoặc mật khẩu không đúng');
    }

    if (!user.confirmed) {
      return AuthResultEmailNotConfirmed(request.email);
    }

    _currentUser = user;
    return AuthResultSuccess(AppUser(
      id: 'mock_${_nextId++}',
      email: user.email,
      fullName: user.fullName,
    ));
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_users.any((u) => u.email == request.email)) {
      return AuthResultError('Email này đã được đăng ký');
    }

    if (request.password.length < 6) {
      return AuthResultError('Mật khẩu phải có ít nhất 6 ký tự');
    }

    _users.add(_MockUser(
      email: request.email,
      password: request.password,
      fullName: request.fullName,
      confirmed: false,
    ));

    return AuthResultNeedsVerification(
      AppUser(id: 'mock_${_nextId++}', email: request.email, fullName: request.fullName),
      request.email,
    );
  }

  @override
  Future<AuthResult> confirmEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = _users.indexWhere((u) => u.email == email);
    if (idx < 0) {
      return AuthResultError('Email không tồn tại');
    }

    _users[idx] = _users[idx].copyWith(confirmed: true);
    return AuthResultSuccess(AppUser(
      id: 'mock_${_nextId++}',
      email: email,
      fullName: _users[idx].fullName,
    ));
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    // Mock: no-op, verification email already "sent"
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users.cast<_MockUser?>().firstWhere(
      (u) => u!.email == email,
      orElse: () => null,
    );

    if (user == null) {
      // Vẫn trả về thành công để không lộ email
      return;
    }

    final token = _generateToken();
    _resetTokens[token] = email;
  }

  @override
  Future<AuthResult> verifyResetToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final email = _resetTokens[token];
    if (email == null) {
      return AuthResultError('Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn');
    }

    final user = _users.cast<_MockUser?>().firstWhere(
      (u) => u!.email == email,
      orElse: () => null,
    );

    if (user == null) {
      return AuthResultError('Người dùng không tồn tại');
    }

    return AuthResultSuccess(AppUser(
      id: 'mock_reset',
      email: email,
      fullName: user.fullName,
    ));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) {
      // Nếu không có currentUser, tìm qua reset tokens
      return;
    }

    final idx = _users.indexWhere((u) => u.email == _currentUser!.email);
    if (idx >= 0) {
      _users[idx] = _users[idx].copyWith(password: newPassword);
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  AppUser? get currentUser {
    if (_currentUser == null) return null;
    return AppUser(
      id: 'mock_current',
      email: _currentUser!.email,
      fullName: _currentUser!.fullName,
    );
  }

  @override
  Future<AppUser?> fetchProfile() async {
    if (_currentUser == null) return null;
    return currentUser;
  }

  @override
  Future<void> requestSeller() async {
    // mock: no-op
  }

  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
