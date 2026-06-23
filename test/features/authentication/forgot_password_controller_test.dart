import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/forgot_password_controller.dart';

void main() {
  group('ForgotPasswordController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late ForgotPasswordController controller;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      controller = ForgotPasswordController(auth: mockAuth, firestore: mockFirestore);
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

    group('Email Registration Verification (TC-38 & TC-39)', () {
      test('TC-38: email terdaftar -> isEmailRegistered returns true', () async {
        const email = 'registered@email.com';
        
        // Seed database with registered user
        await mockFirestore.collection('users').add({
          'uid': 'user_123',
          'email': email,
          'fullName': 'Test User',
          'isActive': true,
        });

        final isRegistered = await controller.isEmailRegistered(email);
        expect(isRegistered, true);
      });

      test('TC-39: email tidak terdaftar -> isEmailRegistered returns false', () async {
        const email = 'unregistered@email.com';

        // Do not seed the database with this user
        final isRegistered = await controller.isEmailRegistered(email);
        expect(isRegistered, false);
      });

      test('Branch: isEmailRegistered handles Firestore exceptions gracefully', () async {
        final badFirestore = MockFirestoreCustomException();
        final badController = ForgotPasswordController(auth: mockAuth, firestore: badFirestore);

        final isRegistered = await badController.isEmailRegistered('any@email.com');
        expect(isRegistered, false);
      });
    });

    group('Password Reset Link Dispatch & Loading State (TC-38)', () {
      test('TC-38: email terdaftar -> sendPasswordReset triggers auth dispatch & loading states', () async {
        const email = 'registered@email.com';

        // Verify initial state
        expect(controller.isLoading, false);

        // Capture loading state changes during execution
        bool wasLoadingStateTrue = false;
        controller.addListener(() {
          if (controller.isLoading) {
            wasLoadingStateTrue = true;
          }
        });

        // Trigger password reset
        await controller.sendPasswordReset(email);

        // Verify loading updates and auth call completion
        expect(controller.isLoading, false);
        expect(wasLoadingStateTrue, true);
      });

      test('Branch: sendPasswordReset propagates auth exceptions correctly', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('user-not-found', 'User not found.');
        final errorController = ForgotPasswordController(auth: mockAuthCustom, firestore: mockFirestore);

        try {
          await errorController.sendPasswordReset('unknown@email.com');
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<FirebaseAuthException>());
        }

        // Verify loading is reset to false after throwing
        expect(errorController.isLoading, false);
      });
    });
  });
}

// Custom mock exception classes
class MockFirebaseAuthCustomException extends MockFirebaseAuth {
  final String exceptionCode;
  final String exceptionMessage;

  MockFirebaseAuthCustomException(this.exceptionCode, this.exceptionMessage);

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    throw FirebaseAuthException(
      code: exceptionCode,
      message: exceptionMessage,
    );
  }
}

class MockFirestoreCustomException extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw Exception('Firestore query failed');
  }
}
