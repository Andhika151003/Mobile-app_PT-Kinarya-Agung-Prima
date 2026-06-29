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
      test('TC-41: email kosong atau null -> error "Email is required"', () {
        expect(controller.validateEmail(null), 'Email is required');
        expect(controller.validateEmail(''), 'Email is required');
      });

      test('TC-40: format email invalid -> error "Enter a valid email address"', () {
        expect(controller.validateEmail('invalid'), 'Enter a valid email address');
        expect(controller.validateEmail('user@'), 'Enter a valid email address');
        expect(controller.validateEmail('user@domain'), 'Enter a valid email address');
      });

      test('TC-40: format email valid -> null (no error)', () {
        expect(controller.validateEmail('user@example.com'), null);
        expect(controller.validateEmail('registered@email.com'), null);
      });
    });
  });
}
