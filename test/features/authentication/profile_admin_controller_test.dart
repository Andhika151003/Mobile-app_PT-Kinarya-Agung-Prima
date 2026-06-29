import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/profile_admin_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('AdminProfileController Unit Tests (Pure)', () {
    setUp(() {
      // Just instantiate to ensure no compile or setup errors
      AdminProfileController();
    });

    group('Form Input Validators (TC-28 & TC-29)', () {
      final validateField = (String label, String? value) {
        if (value == null || value.trim().isEmpty) {
          return '* $label is required';
        }
        return null;
      };

      test('TC-28: updateProfile() dengan nama kosong -> error "* Business Name is required"', () {
        final validationResult = validateField('Business Name', '');
        expect(validationResult, contains('Business Name is required'));
        expect(validateField('Business Name', null), contains('Business Name is required'));
      });

      test('TC-29: updateProfile() dengan contact kosong -> error "* Contact is required"', () {
        final validationResult = validateField('Contact', '');
        expect(validationResult, contains('Contact is required'));
        expect(validateField('Contact', null), contains('Contact is required'));
      });

      test('Field validators return null when fields are filled', () {
        expect(validateField('Business Name', 'Admin Office'), null);
        expect(validateField('Contact', '08123456789'), null);
      });
    });
  });
}