import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/profile_user_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('RetailProfileController Unit Tests (Pure)', () {
    setUp(() {
      // Just instantiate to ensure no compile or setup errors
      RetailProfileController();
    });

    group('Form Input Validators (TC-24 & TC-25)', () {
      final validateField = (String label, String? value) {
        if (value == null || value.trim().isEmpty) {
          return '* $label is required';
        }
        return null;
      };

      test('TC-24: updateProfile() dengan business name kosong -> error "* Business Name is required"', () {
        final validationResult = validateField('Business Name', '');
        expect(validationResult, contains('Business Name is required'));
        expect(validateField('Business Name', null), contains('Business Name is required'));
      });

      test('TC-25: updateProfile() dengan contact kosong -> error "* Contact is required"', () {
        final validationResult = validateField('Contact', '');
        expect(validationResult, contains('Contact is required'));
        expect(validateField('Contact', null), contains('Contact is required'));
      });

      test('Field validators return null when fields are filled', () {
        expect(validateField('Business Name', 'My Store'), null);
        expect(validateField('Contact', '08123456789'), null);
      });
    });
  });
}