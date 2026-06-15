import '../exceptions/app_exception.dart';

sealed class Failure {
  final String message;

  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

Failure failureFromException(AppException e) {
  return switch (e) {
    AuthException _ => AuthFailure(e.message),
    NetworkException _ => NetworkFailure(e.message),
    ServerException _ => ServerFailure(e.message),
    ValidationException _ => ValidationFailure(e.message),
    NotFoundException _ => NotFoundFailure(e.message),
    _ => ServerFailure(e.message),
  };
}
