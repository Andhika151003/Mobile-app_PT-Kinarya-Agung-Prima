import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/forgot_password_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('ForgotPasswordController Unit Tests (Pure)', () {
    late ForgotPasswordController controller;

    setUp(() {
      controller = ForgotPasswordController();
    });

    group('Email Input Validation (TC-40 & TC-41)', () {
      test('TC-41: email kosong atau null -> error "Email wajib diisi"', () {
        expect(controller.validateEmail(null), 'Email wajib diisi');
        expect(controller.validateEmail(''), 'Email wajib diisi');
      });

      test('TC-40: format email invalid -> error "Harap masukkan alamat email yang valid"', () {
        expect(controller.validateEmail('invalid'), 'Harap masukkan alamat email yang valid');
        expect(controller.validateEmail('user@'), 'Harap masukkan alamat email yang valid');
        expect(controller.validateEmail('user@domain'), 'Harap masukkan alamat email yang valid');
      });

      test('TC-40: format email valid -> null (no error)', () {
        expect(controller.validateEmail('user@example.com'), null);
        expect(controller.validateEmail('registered@email.com'), null);
      });
    });
  });
}