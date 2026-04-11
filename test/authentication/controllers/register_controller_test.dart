import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/register_controller.dart';

void main() {
  late RegisterController registerController;

  setUp(() {
    registerController = RegisterController();
  });

  group('RegisterController - Validasi Nama Lengkap', () {
    test('Harus error jika nama kosong', () {
      final result = registerController.validateFullName('');
      expect(result, 'Full Name is required');
    });

    test('Harus null jika nama diisi dengan benar', () {
      final result = registerController.validateFullName('Amirul');
      expect(result, null);
    });
  });

  group('RegisterController - Validasi Email', () {
    test('Harus error jika format email salah', () {
      final result = registerController.validateEmail('amirul@mail');
      expect(result, 'Please enter a valid email address');
    });

    test('Harus null jika email benar', () {
      final result = registerController.validateEmail('amirul@example.com');
      expect(result, null);
    });
  });

  group('RegisterController - Validasi Password', () {
    test('Harus error jika password kurang dari 8 karakter', () {
      final result = registerController.validatePassword('123');
      expect(result, 'Password must be at least 8 characters');
    });
  });
}
