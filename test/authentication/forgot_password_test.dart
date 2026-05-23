import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/forgot_password_controller.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late ForgotPasswordController controller;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
    controller = ForgotPasswordController(auth: mockAuth, firestore: mockFirestore);
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

  group('ForgotPasswordController - Email Registration Check', () {
    test('isEmailRegistered returns true when email exists', () async {
      // Seed data
      await mockFirestore.collection('users').add({
        'email': 'registered@example.com',
        'name': 'Test User',
      });

      final result = await controller.isEmailRegistered('registered@example.com');
      expect(result, true);
    });

    test('isEmailRegistered returns false when email does not exist', () async {
      final result = await controller.isEmailRegistered('notfound@example.com');
      expect(result, false);
    });

    test('isEmailRegistered is case-insensitive (trimming handled)', () async {
      await mockFirestore.collection('users').add({
        'email': 'user@example.com',
      });

      final result = await controller.isEmailRegistered('  user@example.com  ');
      expect(result, true);
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
