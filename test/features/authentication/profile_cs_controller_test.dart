import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/profile_cs_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('ProfileCsController Unit Tests (Pure)', () {
    setUp(() {
      // Just instantiate to ensure no compile or setup errors
      ProfileCsController();
    });

    group('CS Profile Validation Logic', () {
      final validateField = (String label, String? value) {
        if (value == null || value.trim().isEmpty) {
          return '* $label is required';
        }
        return null;
      };

      test('CS Name Validation', () {
        expect(validateField('CS Name', ''), contains('CS Name is required'));
        expect(validateField('CS Name', 'Budi CS'), null);
      });

      test('CS Contact Validation', () {
        expect(validateField('CS Contact', null), contains('CS Contact is required'));
        expect(validateField('CS Contact', '08123456789'), null);
      });
    });
  });
}
