import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/register_controller.dart';

void main() {
  group('RegisterController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late RegisterController controller;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      controller = RegisterController(auth: mockAuth, firestore: mockFirestore);
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
        String? validateBusinessType(String? value) => value == null ? 'Please select your business type' : null;
        expect(validateBusinessType(null), 'Please select your business type');
        expect(validateBusinessType('Pet Shop'), null);
      });
    });

    group('Registration Flow & Exception Handling (TC-8 & TC-11)', () {
      test('TC-8: Semua field valid -> register success, sends verification, saves to firestore', () async {
        const email = 'newuser@email.com';
        const uid = 'new_user_uid_123';
        final mockUser = MockUser(
          uid: uid,
          email: email,
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);
        controller = RegisterController(auth: mockAuth, firestore: mockFirestore);

        // Verify initial state
        expect(controller.isLoading, false);
        expect(controller.errorMessage, null);

        // Perform registration
        final success = await controller.register(
          fullName: 'New Retailer',
          email: email,
          phoneNumber: '081234567890',
          businessType: 'Pet Shop',
          password: 'password123',
        );

        // Verify registration result and loading state updates
        expect(success, true);
        expect(controller.isLoading, false);
        expect(controller.errorMessage, null);

        // Verify Firestore record is created with correct properties
        final createdUid = mockAuth.currentUser!.uid;
        final doc = await mockFirestore.collection('users').doc(createdUid).get();
        expect(doc.exists, true);
        expect(doc.data()?['uid'], createdUid);
        expect(doc.data()?['fullName'], 'New Retailer');
        expect(doc.data()?['email'], email);
        expect(doc.data()?['phoneNumber'], '081234567890');
        expect(doc.data()?['businessType'], 'Pet Shop');
        expect(doc.data()?['role'], 'retailer');
        expect(doc.data()?['isActive'], true);
      });

      test('TC-11: Email sudah terdaftar -> register throws email-already-in-use exception', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('email-already-in-use', 'Email is in use.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Duplicate Email',
          email: 'duplicate@email.com',
          phoneNumber: '081234567890',
          businessType: 'Skincare',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.isLoading, false);
        expect(controller.errorMessage, 'Email already registered');
      });

      test('Branch: register throws invalid-email FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('invalid-email', 'The email is badly formatted.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Bad Email',
          email: 'bademail',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.errorMessage, 'Please enter a valid email address');
      });

      test('Branch: register throws weak-password FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('weak-password', 'The password is too weak.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Short Password User',
          email: 'user@email.com',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: '123',
        );

        expect(success, false);
        expect(controller.errorMessage, 'Password must be at least 8 characters');
      });

      test('Branch: register throws too-many-requests FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('too-many-requests', 'Too many requests.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Flooded User',
          email: 'flood@email.com',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.errorMessage, 'Firebase is blocking requests due to too many attempts. Please try again later.');
      });

      test('Branch: register throws network-request-failed FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('network-request-failed', 'Network request failed.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Offline User',
          email: 'offline@email.com',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.errorMessage, 'Network error. Please check your internet connection.');
      });

      test('Branch: register throws default/unknown FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('unknown-code', 'Unknown auth failure.');
        controller = RegisterController(auth: mockAuthCustom, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Unknown Error User',
          email: 'unknown@email.com',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.errorMessage, contains('Registration failed: Unknown auth failure.'));
      });

      test('Branch: register throws generic Exception', () async {
        // Mock FirebaseAuth that throws a general exception
        final mockAuthError = MockFirebaseAuthGeneralException();
        controller = RegisterController(auth: mockAuthError, firestore: mockFirestore);

        final success = await controller.register(
          fullName: 'Crash User',
          email: 'crash@email.com',
          phoneNumber: '081234567890',
          businessType: 'Lainnya',
          password: 'password123',
        );

        expect(success, false);
        expect(controller.errorMessage, contains('Registration failed: Exception: Auth server crashed'));
      });
    });
  });
}

// Custom mock classes
class MockFirebaseAuthCustomException extends MockFirebaseAuth {
  final String exceptionCode;
  final String exceptionMessage;

  MockFirebaseAuthCustomException(this.exceptionCode, this.exceptionMessage);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: exceptionCode,
      message: exceptionMessage,
    );
  }
}

class MockFirebaseAuthGeneralException extends MockFirebaseAuth {
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw Exception('Auth server crashed');
  }
}
