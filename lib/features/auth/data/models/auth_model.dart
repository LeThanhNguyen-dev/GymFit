class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;
}

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    this.fullName,
  });

  final String email;
  final String password;
  final String? fullName;
}

class AppUser {
  const AppUser({required this.id, required this.email, this.fullName});

  final String id;
  final String email;
  final String? fullName;
}
