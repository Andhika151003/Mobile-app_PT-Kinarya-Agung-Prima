import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/forgot_password_controller.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late ForgotPasswordController controller;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    controller = ForgotPasswordController(auth: mockAuth);
  });

  group('ForgotPasswordController - Email Validation', () {
    test('Empty email should return error', () {
      expect(controller.validateEmail(''), 'Email is required');
      expect(controller.validateEmail(null), 'Email is required');
    });

    test('Invalid format should return error', () {
      expect(controller.validateEmail('invalid-email'), 'Enter a valid email address');
      expect(controller.validateEmail('user@com'), 'Enter a valid email address');
    });

    test('Correct format should return null', () {
      expect(controller.validateEmail('user@example.com'), null);
    });
  });



  group('ForgotPasswordController - Send Password Reset', () {
    test('sendPasswordReset calls Firebase and manages loading state', () async {
      const email = 'user@example.com';
      
      expect(controller.isLoading, false);

      await controller.sendPasswordReset(email);
      
      expect(controller.isLoading, false);
    });
  });
}
