import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:ecommerce/core/firebase_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockUserCredential extends Fake implements UserCredential {
  final User _user;
  MockUserCredential(this._user);

  @override
  User? get user => _user;
}

class CustomMockAuth extends MockFirebaseAuth {
  final Map<String, MockUser> _usersByEmail = {};
  final Map<String, MockUser> _usersByUid = {};
  MockUser? _currentUser;
  
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  final StreamController<User?> _userChangesController = StreamController<User?>.broadcast();

  CustomMockAuth() : super(signedIn: false);

  @override
  User? get currentUser => _currentUser;

  Stream<User?> _createStream(StreamController<User?> controller) async* {
    yield _currentUser;
    yield* controller.stream;
  }

  @override
  Stream<User?> authStateChanges() => _createStream(_authStateController);

  @override
  Stream<User?> userChanges() => _createStream(_userChangesController);

  @override
  Stream<User?> idTokenChanges() => _createStream(_authStateController);

  void _updateUser(MockUser? user) {
    _currentUser = user;
    _authStateController.add(user);
    _userChangesController.add(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final user = _usersByEmail[cleanEmail];
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Email not found',
      );
    }
    if (password != '12345678') {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Incorrect password',
      );
    }
    _updateUser(user);
    return MockUserCredential(user);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (_usersByEmail.containsKey(cleanEmail)) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already registered',
      );
    }
    final uid = 'uid_${cleanEmail.split('@')[0]}';
    final isSeedUser = cleanEmail == 'ad@email.com' ||
        cleanEmail == 'rt@email.com' ||
        cleanEmail == 'cs@email.com' ||
        cleanEmail == 'inactive@email.com';
    final user = MockUser(
      uid: uid,
      email: cleanEmail,
      displayName: cleanEmail.split('@')[0],
      isEmailVerified: isSeedUser,
    );
    _usersByEmail[cleanEmail] = user;
    _usersByUid[uid] = user;
    if (_currentUser?.email != 'ad@email.com') {
      _updateUser(user);
    }
    return MockUserCredential(user);
  }

  @override
  Future<void> signOut() async {
    _updateUser(null);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    final cleanEmail = email.trim();
    if (!_usersByEmail.containsKey(cleanEmail)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found with this email.',
      );
    }
  }
}

Future<void> setupTestEnvironment() async {
  await dotenv.load(fileName: ".env");
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Already initialized or ignore
  }

  final mockAuth = CustomMockAuth();
  final mockFirestore = FakeFirebaseFirestore();

  AppFirebase.mockAuth = mockAuth;
  AppFirebase.mockFirestore = mockFirestore;

  // 1. Admin
  final adminCred = await mockAuth.createUserWithEmailAndPassword(
    email: 'ad@email.com',
    password: '12345678',
  );
  await mockFirestore.collection('users').doc(adminCred.user!.uid).set({
    'uid': adminCred.user!.uid,
    'email': 'ad@email.com',
    'fullName': 'Distributor Admin',
    'role': 'admin',
    'isActive': true,
    'phoneNumber': '08123456789',
    'businessType': 'UD (Usaha Dagang)',
  });

  // 2. Retailer
  final retailerCred = await mockAuth.createUserWithEmailAndPassword(
    email: 'rt@email.com',
    password: '12345678',
  );
  await mockFirestore.collection('users').doc(retailerCred.user!.uid).set({
    'uid': retailerCred.user!.uid,
    'email': 'rt@email.com',
    'fullName': 'Toko Retailer',
    'role': 'retailer',
    'isActive': true,
    'phoneNumber': '08234567890',
    'businessType': 'Pet Shop',
  });

  // 3. CS
  final csCred = await mockAuth.createUserWithEmailAndPassword(
    email: 'cs@email.com',
    password: '12345678',
  );
  await mockFirestore.collection('users').doc(csCred.user!.uid).set({
    'uid': csCred.user!.uid,
    'email': 'cs@email.com',
    'fullName': 'Customer Support',
    'role': 'cs',
    'isActive': true,
    'phoneNumber': '08345678901',
    'department': 'Technical Support',
  });

  // 4. Inactive Retailer
  final inactiveCred = await mockAuth.createUserWithEmailAndPassword(
    email: 'inactive@email.com',
    password: '12345678',
  );
  await mockFirestore.collection('users').doc(inactiveCred.user!.uid).set({
    'uid': inactiveCred.user!.uid,
    'email': 'inactive@email.com',
    'fullName': 'Toko Inactive',
    'role': 'retailer',
    'isActive': false,
    'phoneNumber': '08456789012',
    'businessType': 'Skincare',
  });

  // Reset the auth current user state to signed out
  await mockAuth.signOut();
}

Future<void> loginAs(WidgetTester tester, String email, String password) async {
  final emailFinder = find.byKey(const Key('emailField'));
  final passwordFinder = find.byKey(const Key('passwordField'));
  final loginButtonFinder = find.byKey(const Key('loginButton'));

  expect(emailFinder, findsOneWidget);
  expect(passwordFinder, findsOneWidget);
  expect(loginButtonFinder, findsOneWidget);

  await tester.ensureVisible(emailFinder);
  await tester.enterText(emailFinder, email);
  await tester.ensureVisible(passwordFinder);
  await tester.enterText(passwordFinder, password);
  await tester.ensureVisible(loginButtonFinder);
  await tester.tap(loginButtonFinder);
  await tester.pumpAndSettle();
}

Future<void> goToRegister(WidgetTester tester) async {
  final signUpTextFinder = find.text('Sign Up');
  expect(signUpTextFinder, findsOneWidget);
  await tester.tap(signUpTextFinder);
  await tester.pumpAndSettle();
}

Future<void> goToProfile(WidgetTester tester) async {
  final profileTabFinder = find.text('Profile');
  expect(profileTabFinder, findsOneWidget);
  await tester.tap(profileTabFinder);
  await tester.pumpAndSettle();
}

Future<void> goToStaffManagement(WidgetTester tester) async {
  // Assuming already on profile admin view
  final staffManagementFinder = find.text('Staff Management');
  expect(staffManagementFinder, findsOneWidget);
  await tester.tap(staffManagementFinder);
  await tester.pumpAndSettle();
}

Future<void> goToRetailerManagement(WidgetTester tester) async {
  // Assuming already on dashboard admin view
  final viewAllFinder = find.text('View All');
  expect(viewAllFinder, findsOneWidget);
  await tester.tap(viewAllFinder);
  await tester.pumpAndSettle();
}
