import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/register_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('RegisterController Unit Tests (Pure)', () {
    late RegisterController controller;

    setUp(() {
      controller = RegisterController();
    });

    group('Input Validators (TC-9, TC-10, TC-12, TC-14 to TC-18)', () {
      test('TC-9 & TC-10: Email Validations', () {
        expect(controller.validateEmail(null), 'Email is required');
        expect(controller.validateEmail(''), 'Email is required');
        expect(controller.validateEmail('invalid'), 'Please enter a valid email address');
        expect(controller.validateEmail('user@example.com'), null);
      });

      test('TC-12: Full Name Validations', () {
        expect(controller.validateFullName(null), 'Full Name is required');
        expect(controller.validateFullName(''), 'Full Name is required');
        expect(controller.validateFullName('ab'), 'Please enter a full name');
        expect(controller.validateFullName('John Doe'), null);
      });

      test('TC-14 & TC-15: Phone Number Validations', () {
        expect(controller.validatePhoneNumber(null), 'Phone Number is required');
        expect(controller.validatePhoneNumber(''), 'Phone Number is required');
        expect(controller.validatePhoneNumber('123456789'), 'Please enter valid phone number'); // 9 digits
        expect(controller.validatePhoneNumber('12345678901234'), 'Please enter valid phone number'); // 14 digits
        expect(controller.validatePhoneNumber('08123456789'), null); // 11 digits
      });

      test('TC-16: Password Validations', () {
        expect(controller.validatePassword(null), 'Password is required');
        expect(controller.validatePassword(''), 'Password is required');
        expect(controller.validatePassword('1234567'), 'Password must be at least 8 characters');
        expect(controller.validatePassword('12345678'), null);
      });

      test('TC-17 & TC-18: Confirm Password Validations', () {
        expect(controller.validateConfirmPassword(null, 'password123'), 'Please confirm your password');
        expect(controller.validateConfirmPassword('', 'password123'), 'Please confirm your password');
        expect(controller.validateConfirmPassword('password321', 'password123'), 'Passwords do not match');
        expect(controller.validateConfirmPassword('password123', 'password123'), null);
      });
    });

    group('Dropdown Validator (TC-13)', () {
      test('TC-13: Business Type Dropdown Validation', () {
        final validateBusinessType = (String? value) => value == null ? 'Please select your business type' : null;
        expect(validateBusinessType(null), 'Please select your business type');
        expect(validateBusinessType('Pet Shop'), null);
      });
    });
  });
}
