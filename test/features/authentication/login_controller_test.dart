import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/login_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('LoginController Unit Tests (Pure)', () {
    late LoginController loginController;

    setUp(() {
      loginController = LoginController();
    });

    group('Input Validation (TC-6 & TC-7)', () {
      test('TC-6: email kosong atau null -> error "Email wajib diisi"', () {
        expect(loginController.validateEmailInput(null), 'Email wajib diisi');
        expect(loginController.validateEmailInput(''), 'Email wajib diisi');
      });

      test('TC-6 (Format): email format salah -> error "Harap masukkan alamat email yang valid"', () {
        expect(loginController.validateEmailInput('invalidemail'), 'Harap masukkan alamat email yang valid');
        expect(loginController.validateEmailInput('user@'), 'Harap masukkan alamat email yang valid');
        expect(loginController.validateEmailInput('user@domain'), 'Harap masukkan alamat email yang valid');
      });

      test('TC-6 (Format): email format benar -> null (no error)', () {
        expect(loginController.validateEmailInput('user@example.com'), null);
        expect(loginController.validateEmailInput('ad@email.com'), null);
      });

      test('TC-7: password kosong atau null -> error "Password wajib diisi"', () {
        expect(loginController.validatePassword(null), 'Password wajib diisi');
        expect(loginController.validatePassword(''), 'Password wajib diisi');
      });

      test('TC-7: password terisi -> null (no error)', () {
        expect(loginController.validatePassword('12345678'), null);
      });
    });
  });
}