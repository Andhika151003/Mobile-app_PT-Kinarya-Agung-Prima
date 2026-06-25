import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:ecommerce/core/firebase_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  SharedPreferences.setMockInitialValues({'hasSeenPromo_v1': true});
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPromo_v1', true);
  } catch (e) {
    //asdasd
  }

  final mockAuth = CustomMockAuth();
  final mockFirestore = FakeFirebaseFirestore();

  AppFirebase.mockAuth = mockAuth;
  AppFirebase.mockFirestore = mockFirestore;

  CartController.setAuthInstance(mockAuth);

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

  // 5. Products
  await mockFirestore.collection('products').doc('PROD-1').set({
    'retailerId': adminCred.user!.uid,
    'name': 'Whiskas',
    'category': 'Pet Food',
    'price': 50000,
    'stock': 10,
    'description': 'Tuna flavor',
    'imageUrl': '',
    'monthlySales': 0,
    'revenue': 0,
  });

  await mockFirestore.collection('products').doc('PROD-2').set({
    'retailerId': adminCred.user!.uid,
    'name': 'Pedigree',
    'category': 'Pet Food',
    'price': 200000,
    'stock': 5,
    'description': 'Beef flavor',
    'imageUrl': '',
    'monthlySales': 0,
    'revenue': 0,
  });

  // 6. Promotions
  await mockFirestore.collection('promotions').doc('PROMO-1').set({
    'title': 'Diskon Spesial',
    'description': 'Diskon 10% untuk semua produk',
    'discountType': 'percentage',
    'discountValue': 10.0,
    'productIds': <dynamic>[],
    'applicableTo': 'all',
    'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
    'startTime': '00:00',
    'endTime': '23:59',
    'status': 'active',
    'imageUrl': '',
    'sku': 'PROMO10',
    'createdAt': Timestamp.now(),
    'createdBy': adminCred.user!.uid,
    'maxDiscount': 100000.0,
  });

  // Add Dummy Orders for testing
  await mockFirestore.collection('orders').doc('ORD-12345').set({
    'orderId': 'ORD-12345',
    'userId': retailerCred.user!.uid,
    'fullName': 'Toko Retailer',
    'shippingAddress': 'Jl. Dummy 123',
    'phoneNumber': '08234567890',
    'paymentMethod': 'Transfer Bank',
    'promoCode': '',
    'subtotal': 100000,
    'shippingCost': 10000,
    'tax': 0,
    'discountAmount': 0,
    'total': 110000,
    'items': [
      {
        'productId': 'PROD-1',
        'title': 'Whiskas',
        'variant': 'Tuna',
        'quantity': 2,
        'price': 50000,
      }
    ],
    'status': 'Paid',
    'createdAt': Timestamp.now(),
    'paidAt': Timestamp.now(),
  });

  await mockFirestore.collection('orders').doc('ORD-67890').set({
    'orderId': 'ORD-67890',
    'userId': retailerCred.user!.uid,
    'fullName': 'Toko Retailer',
    'shippingAddress': 'Jl. Dummy 123',
    'phoneNumber': '08234567890',
    'paymentMethod': 'Transfer Bank',
    'promoCode': '',
    'subtotal': 200000,
    'shippingCost': 15000,
    'tax': 0,
    'discountAmount': 0,
    'total': 215000,
    'items': [
      {
        'productId': 'PROD-2',
        'title': 'Pedigree',
        'variant': 'Beef',
        'quantity': 1,
        'price': 200000,
      }
    ],
    'status': 'Paid',
    'createdAt': Timestamp.now(),
    'paidAt': Timestamp.now(),
  });

  // 7. Complaints
  await mockFirestore.collection('complaints').doc('COMP-1').set({
    'userId': retailerCred.user!.uid,
    'storeName': 'Toko Retailer',
    'title': 'Barang Rusak',
    'imgUrl': '',
    'orderId': 'ORD-12345',
    'productName': 'Whiskas',
    'issueType': 'Barang Rusak',
    'description': 'Kemasan whiskas robek saat diterima',
    'imageUrls': <String>[],
    'status': 'pending',
    'createdAt': Timestamp.now(),
  });

  // Reset the auth current user state to signed out
  await mockAuth.signOut();
}

Future<void> loginAs(WidgetTester tester, String email, String password) async {
  final emailFinder = find.byKey(const Key('login_email_field'));
  final passwordFinder = find.byKey(const Key('login_password_field'));
  final loginButtonFinder = find.byKey(const Key('login_submit_btn'));

  expect(emailFinder, findsOneWidget);
  expect(passwordFinder, findsOneWidget);
  expect(loginButtonFinder, findsOneWidget);

  await tester.ensureVisible(emailFinder);
  await tester.enterText(emailFinder, email);
  await tester.ensureVisible(passwordFinder);
  await tester.enterText(passwordFinder, password);
  
  await tester.pump(const Duration(milliseconds: 500));
  await tester.ensureVisible(loginButtonFinder);
  await tester.tap(loginButtonFinder);
  await tester.pumpAndSettle();
  
  // Dismiss keyboard/focus and complete transitions
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

Future<void> goToRegister(WidgetTester tester) async {
  final signUpTextFinder = find.text('Daftar');
  expect(signUpTextFinder, findsOneWidget);
  
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(signUpTextFinder);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> goToProfile(WidgetTester tester) async {
  // Ensure keyboard/focus is dismissed to prevent hit-test blocking
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  final profileTabFinder = find.byIcon(Icons.person_outline);
  expect(profileTabFinder, findsWidgets);
  
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(profileTabFinder.last);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

Future<void> goToStaffManagement(WidgetTester tester) async {
  // Assuming already on profile admin view
  final staffManagementFinder = find.text('Manajemen Staf');
  expect(staffManagementFinder, findsOneWidget);
  await tester.tap(staffManagementFinder);
  await tester.pumpAndSettle();
}

Future<void> goToRetailerManagement(WidgetTester tester) async {
  // Assuming already on dashboard admin view
  final viewAllFinder = find.text('Lihat Semua');
  expect(viewAllFinder, findsOneWidget);
  await tester.tap(viewAllFinder);
  await tester.pumpAndSettle();
}
