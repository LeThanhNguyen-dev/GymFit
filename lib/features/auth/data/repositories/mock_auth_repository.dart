import '../models/auth_model.dart';
import 'auth_repository.dart';

class _MockUser {
  const _MockUser({required this.email, required this.password, this.fullName, this.confirmed = false});
  final String email;
  final String password;
  final String? fullName;
  final bool confirmed;
}

class MockAuthRepository implements IAuthRepository {
  final _users = <_MockUser>[];
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

    final newUser = _MockUser(
      email: request.email,
      password: request.password,
      fullName: request.fullName,
      confirmed: true,
    );
    _users.add(newUser);
    _currentUser = newUser;

    return AuthResultSuccess(AppUser(
      id: 'mock_${_nextId++}',
      email: request.email,
      fullName: request.fullName,
    ));
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _users.cast<_MockUser?>().firstWhere(
      (u) => u!.email == email,
      orElse: () => null,
    );
    if (user == null) {
      throw Exception('Email không tồn tại trong hệ thống');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentUser == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    final idx = _users.indexWhere((u) => u.email == _currentUser!.email);
    if (idx >= 0) {
      _users[idx] = _MockUser(
        email: _users[idx].email,
        password: newPassword,
        fullName: _users[idx].fullName,
        confirmed: _users[idx].confirmed,
      );
    }
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

  void confirmEmail(String email) {
    final idx = _users.indexWhere((u) => u.email == email);
    if (idx >= 0) {
      _users[idx] = _MockUser(
        email: _users[idx].email,
        password: _users[idx].password,
        fullName: _users[idx].fullName,
        confirmed: true,
      );
    }
  }
}
