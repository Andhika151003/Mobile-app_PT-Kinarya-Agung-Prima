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
      test('TC-6: email kosong atau null -> error "Email is required"', () {
        expect(loginController.validateEmailInput(null), 'Email is required');
        expect(loginController.validateEmailInput(''), 'Email is required');
      });

      test('TC-6 (Format): email format salah -> error "Please enter a valid email address"', () {
        expect(loginController.validateEmailInput('invalidemail'), 'Please enter a valid email address');
        expect(loginController.validateEmailInput('user@'), 'Please enter a valid email address');
        expect(loginController.validateEmailInput('user@domain'), 'Please enter a valid email address');
      });

      test('TC-6 (Format): email format benar -> null (no error)', () {
        expect(loginController.validateEmailInput('user@example.com'), null);
        expect(loginController.validateEmailInput('ad@email.com'), null);
      });

      test('TC-7: password kosong atau null -> error "Password is required"', () {
        expect(loginController.validatePassword(null), 'Password is required');
        expect(loginController.validatePassword(''), 'Password is required');
      });

      test('TC-7: password terisi -> null (no error)', () {
        expect(loginController.validatePassword('12345678'), null);
      });
    });
  });
}
