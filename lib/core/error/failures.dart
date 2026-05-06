abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class DatabaseFailure extends Failure {
  DatabaseFailure([super.message = 'Gagal mengakses database']);
}

class AuthFailure extends Failure {
  AuthFailure([super.message = 'Autentikasi gagal']);
}

class ValidationFailure extends Failure {
  ValidationFailure([super.message = 'Validasi gagal']);
}
