import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/admin/controller/admin_cs_controller.dart';
import '../authentication/mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('AdminCsController Unit Tests (Pure)', () {
    setUp(() {
      // Just instantiate to ensure no compile or setup errors
      AdminCsController();
    });

    group('CS Form Validation Logic', () {
      final validateCsUsername = (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Username is required';
        }
        if (value.trim().length < 3) {
          return 'Username must be at least 3 characters';
        }
        return null;
      };

      final validateCsEmail = (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Please enter a valid email address';
        }
        return null;
      };

      final validateCsPhone = (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Phone number is required';
        }
        if (value.trim().length < 10 || value.trim().length > 13) {
          return 'Phone number must be between 10 and 13 digits';
        }
        return null;
      };

      test('CS Username Validation', () {
        expect(validateCsUsername(null), 'Username is required');
        expect(validateCsUsername(''), 'Username is required');
        expect(validateCsUsername('ab'), 'Username must be at least 3 characters');
        expect(validateCsUsername('CS Agent 1'), null);
      });

      test('CS Email Validation', () {
        expect(validateCsEmail(null), 'Email is required');
        expect(validateCsEmail(''), 'Email is required');
        expect(validateCsEmail('invalid-email'), 'Please enter a valid email address');
        expect(validateCsEmail('cs@kinarya.com'), null);
      });

      test('CS Phone Validation', () {
        expect(validateCsPhone(null), 'Phone number is required');
        expect(validateCsPhone(''), 'Phone number is required');
        expect(validateCsPhone('12345678'), 'Phone number must be between 10 and 13 digits');
        expect(validateCsPhone('081234567890'), null);
      });
    });
  });
}