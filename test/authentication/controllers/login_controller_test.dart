import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/login_controller.dart';

void main() {
  late LoginController loginController;

  setUp(() {
    loginController = LoginController();
  });

  group('LoginController - Validasi Email', () {
    test('Harus mengembalikan pesan error jika email null', () {
      final result = loginController.validateEmailInput(null);
      expect(result, 'Email is required');
    });

    test('Harus mengembalikan pesan error jika email kosong', () {
      final result = loginController.validateEmailInput('');
      expect(result, 'Email is required');
    });

    test(
      'Harus mengembalikan pesan error jika format email salah (tanpa @)',
      () {
        final result = loginController.validateEmailInput('adminvibe.com');
        expect(result, 'Please enter a valid email address');
      },
    );

    test('Harus mengembalikan null jika format email benar', () {
      final result = loginController.validateEmailInput('admin@vibe.com');
      expect(result, null);
    });
  });

  group('LoginController - Validasi Password', () {
    test('Harus mengembalikan pesan error jika password null', () {
      final result = loginController.validatePassword(null);
      expect(result, 'Password is required');
    });

    test('Harus mengembalikan pesan error jika password kosong', () {
      final result = loginController.validatePassword('');
      expect(result, 'Password is required');
    });

    test('Harus mengembalikan null jika password diisi', () {
      final result = loginController.validatePassword('rahasia123');
      expect(result, null);
    });
  });
}
