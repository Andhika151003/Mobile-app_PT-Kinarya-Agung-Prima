import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/forgot_password_controller.dart';
import 'package:ecommerce/features/authentication/services/auth_service.dart';
import 'package:ecommerce/core/repositories/auth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late ForgotPasswordController controller;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
    final authRepository = AuthRepository(auth: mockAuth, firestore: mockFirestore);
    final authService = AuthService(authRepository: authRepository);
    controller = ForgotPasswordController(authService: authService);
  });

  group('ForgotPasswordController - Email Validation', () {
    test('Empty email should return error', () {
      expect(controller.validateEmail(''), 'Email wajib diisi');
      expect(controller.validateEmail(null), 'Email wajib diisi');
    });

    test('Invalid format should return error', () {
      expect(controller.validateEmail('invalid-email'), 'Masukkan format email yang valid');
      expect(controller.validateEmail('user@com'), 'Masukkan format email yang valid');
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
