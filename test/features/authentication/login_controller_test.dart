import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ecommerce/features/authentication/controllers/login_controller.dart';
import 'package:ecommerce/features/authentication/models/admin.dart';
import 'package:ecommerce/features/authentication/models/cs.dart';
import 'package:ecommerce/features/authentication/models/retailer.dart';

void main() {
  group('LoginController Unit Tests (Whitebox)', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late LoginController loginController;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
    });

    group('Input Validation (TC-6 & TC-7)', () {
      setUp(() {
        mockAuth = MockFirebaseAuth();
        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);
      });

      test('TC-6: email kosong atau null -> error "Email is required"', () {
        expect(loginController.validateEmailInput(null), 'Email is required');
        expect(loginController.validateEmailInput(''), 'Email is required');
      });

      test('TC-6 (Format): email format salah -> error "Please enter a valid email address"', () {
        expect(loginController.validateEmailInput('invalidemail'), 'Please enter a valid email address');
        expect(loginController.validateEmailInput('user@'), 'Please enter a valid email address');
        expect(loginController.validateEmailInput('user@domain'), 'Please enter a valid email address');
      });

      test('TC-6 (Format): email format benar -> null (no error)', () {
        expect(loginController.validateEmailInput('user@example.com'), null);
        expect(loginController.validateEmailInput('ad@email.com'), null);
      });

      test('TC-7: password kosong atau null -> error "Password is required"', () {
        expect(loginController.validatePassword(null), 'Password is required');
        expect(loginController.validatePassword(''), 'Password is required');
      });

      test('TC-7: password terisi -> null (no error)', () {
        expect(loginController.validatePassword('12345678'), null);
      });
    });

    group('Login Flow & Role-Based Redirects (TC-1, TC-2, TC-3)', () {
      test('TC-1: login dengan email ad@email.com, password 12345678 -> success, return AdminUser (Admin Dashboard)', () async {
        const uid = 'admin_uid_123';
        final mockUser = MockUser(
          uid: uid,
          email: 'ad@email.com',
          displayName: 'Admin User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);

        // Seed admin data in fake firestore
        await mockFirestore.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': 'Admin User',
          'email': 'ad@email.com',
          'phoneNumber': '0811223344',
          'role': 'admin',
          'isActive': true,
          'accessLevel': 2,
          'createdAt': Timestamp.now(),
        });

        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        // Verify initial state
        expect(loginController.isLoading, false);
        expect(loginController.errorMessage, null);

        // Perform login
        final result = await loginController.login(
          email: 'ad@email.com',
          password: '12345678',
        );

        // Verify loading updates and result
        expect(loginController.isLoading, false);
        expect(loginController.errorMessage, null);
        expect(result, isA<AdminUser>());
        expect((result as AdminUser).role, 'admin');
      });

      test('TC-2: login dengan email rt@email.com, password 12345678 -> success, return RetailerUser (Retailer Homepage)', () async {
        const uid = 'retailer_uid_123';
        final mockUser = MockUser(
          uid: uid,
          email: 'rt@email.com',
          displayName: 'Retailer User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);

        // Seed retailer data in fake firestore
        await mockFirestore.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': 'Retailer User',
          'email': 'rt@email.com',
          'phoneNumber': '0822334455',
          'role': 'retailer',
          'isActive': true,
          'storeName': 'Kinarya Store',
          'createdAt': Timestamp.now(),
        });

        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        // Perform login
        final result = await loginController.login(
          email: 'rt@email.com',
          password: '12345678',
        );

        // Verify result
        expect(loginController.isLoading, false);
        expect(loginController.errorMessage, null);
        expect(result, isA<RetailerUser>());
        expect((result as RetailerUser).role, 'retailer');
      });

      test('TC-3: login dengan email cs@email.com, password 12345678 -> success, return CsUser (CS Dashboard)', () async {
        const uid = 'cs_uid_123';
        final mockUser = MockUser(
          uid: uid,
          email: 'cs@email.com',
          displayName: 'CS User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);

        // Seed CS data in fake firestore
        await mockFirestore.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': 'CS User',
          'email': 'cs@email.com',
          'phoneNumber': '0833445566',
          'role': 'cs',
          'isActive': true,
          'handledTickets': 5,
          'createdAt': Timestamp.now(),
        });

        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        // Perform login
        final result = await loginController.login(
          email: 'cs@email.com',
          password: '12345678',
        );

        // Verify result
        expect(loginController.isLoading, false);
        expect(loginController.errorMessage, null);
        expect(result, isA<CsUser>());
        expect((result as CsUser).role, 'cs');
      });
    });

    group('Inactive and Error Handling Flows (TC-4, TC-5 & Exceptions)', () {
      test('TC-4: login dengan akun yang sudah dinonaktifkan -> error message contains "Account Deactivated" & fetches admin phone', () async {
        const uid = 'inactive_uid';
        final mockUser = MockUser(
          uid: uid,
          email: 'inactive@email.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);

        // Seed deactivated retailer user
        await mockFirestore.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': 'Inactive User',
          'email': 'inactive@email.com',
          'phoneNumber': '0844556677',
          'role': 'retailer',
          'isActive': false,
          'createdAt': Timestamp.now(),
        });

        // Seed an admin to fetch phone number from
        await mockFirestore.collection('users').doc('admin_contact').set({
          'uid': 'admin_contact',
          'fullName': 'System Admin',
          'email': 'admin@email.com',
          'phoneNumber': '08123456789',
          'role': 'admin',
          'isActive': true,
          'createdAt': Timestamp.now(),
        });

        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        // Perform login
        final result = await loginController.login(
          email: 'inactive@email.com',
          password: '12345678',
        );

        // Assert user is logged out from firebase, result is null, errorMessage is set, and admin phone is fetched
        expect(result, null);
        expect(loginController.errorMessage, contains('Account Deactivated'));
        expect(loginController.deactivatedAdminPhone, '08123456789');
        expect(mockAuth.currentUser, null); // verifies signOut was called
      });

      test('TC-5: login dengan email salah atau password salah -> user-not-found', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('user-not-found', 'The email address is not registered.');
        loginController = LoginController(auth: mockAuthCustom, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'notfound@email.com',
          password: 'wrongpassword',
        );

        expect(result, null);
        expect(loginController.errorMessage, 'Email not found');
      });

      test('TC-5 (Password Salah): incorrect password -> wrong-password', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('wrong-password', 'The password is invalid.');
        loginController = LoginController(auth: mockAuthCustom, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'registered@email.com',
          password: 'wrongpassword',
        );

        expect(result, null);
        expect(loginController.errorMessage, 'Incorrect password');
      });

      test('Branch: login throws other generic FirebaseAuthException', () async {
        // We can mock FirebaseAuth to throw custom exception
        final mockAuthCustom = MockFirebaseAuthCustomException('invalid-email', 'The email address is badly formatted.');
        loginController = LoginController(auth: mockAuthCustom, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'invalid',
          password: '123',
        );

        expect(result, null);
        expect(loginController.errorMessage, 'Please enter a valid email address');
      });

      test('Branch: login throws user-disabled FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('user-disabled', 'The user account has been disabled by an administrator.');
        loginController = LoginController(auth: mockAuthCustom, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'disabled@email.com',
          password: '123',
        );

        expect(result, null);
        expect(loginController.errorMessage, 'This account has been disabled');
      });

      test('Branch: login throws default/unknown FirebaseAuthException', () async {
        final mockAuthCustom = MockFirebaseAuthCustomException('unknown-code', 'Some error happened.');
        loginController = LoginController(auth: mockAuthCustom, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'unknown@email.com',
          password: '123',
        );

        expect(result, null);
        expect(loginController.errorMessage, contains('Login failed: Some error happened.'));
      });

      test('Branch: document not found in firestore', () async {
        const uid = 'no_doc_uid';
        final mockUser = MockUser(
          uid: uid,
          email: 'nodoc@email.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);

        // We do NOT seed firestore document
        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        final result = await loginController.login(
          email: 'nodoc@email.com',
          password: '123',
        );

        expect(result, null);
        expect(loginController.errorMessage, contains('User data not found'));
      });

      test('Branch: General error (e.g. firestore throws Exception)', () async {
        const uid = 'err_uid';
        final mockUser = MockUser(
          uid: uid,
          email: 'err@email.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);
        final mockFirestoreCustom = MockFirestoreCustomException();

        loginController = LoginController(auth: mockAuth, firestore: mockFirestoreCustom);

        final result = await loginController.login(
          email: 'err@email.com',
          password: '123',
        );

        expect(result, null);
        expect(loginController.errorMessage, contains('Login failed: Exception: Firestore is broken'));
      });
    });

    group('Logout & General', () {
      test('Logout should sign out user from Firebase', () async {
        final mockUser = MockUser(uid: 'uid123', email: 'user@email.com');
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        loginController = LoginController(auth: mockAuth, firestore: mockFirestore);

        expect(mockAuth.currentUser, isNotNull);
        await loginController.logout();
        expect(mockAuth.currentUser, isNull);
      });
    });
  });
}

// Custom mock classes to test specific exception branches
class MockFirebaseAuthCustomException extends MockFirebaseAuth {
  final String exceptionCode;
  final String exceptionMessage;

  MockFirebaseAuthCustomException(this.exceptionCode, this.exceptionMessage);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
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
    throw Exception('Firestore is broken');
  }
}
