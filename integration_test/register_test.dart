import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 1 - Register', () {
    Future<void> fillRegisterForm(
      WidgetTester tester, {
      required String email,
      required String fullName,
      required String businessType,
      required String phone,
      required String password,
      required String confirmPassword,
    }) async {
      await tester.enterText(find.byKey(const Key('emailField')), email);
      await tester.enterText(find.byKey(const Key('fullNameField')), fullName);
      
      if (businessType.isNotEmpty) {
        await tester.tap(find.byKey(const Key('businessTypeDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(businessType).last);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('phoneField')), phone);
      await tester.enterText(find.byKey(const Key('passwordField')), password);
      await tester.enterText(find.byKey(const Key('confirmPasswordField')), confirmPassword);
      await tester.pumpAndSettle();
    }

    testWidgets('TC-8: Registrasi data lengkap dan valid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Verify Your Email'), findsOneWidget);
    });

    testWidgets('TC-9: Email kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: '',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('TC-10: Format email invalid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'invalid-email',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('TC-11: Email sudah terdaftar', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'rt@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email already registered'), findsOneWidget);
    });

    testWidgets('TC-12: Full name kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: '',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsOneWidget);
    });

    testWidgets('TC-13: Business type tidak dipilih', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: '',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please select your business type'), findsOneWidget);
    });

    testWidgets('TC-14: Phone kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Phone Number is required'), findsOneWidget);
    });

    testWidgets('TC-15: Phone kurang dari 10 digit', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      // 9 digits
      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '812345678',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter valid phone number'), findsOneWidget);
    });

    testWidgets('TC-16: Password kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: '',
        confirmPassword: 'password123',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('TC-17: Confirm password kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: '',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('TC-18: Password dan confirm tidak sama', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await goToRegister(tester);

      await fillRegisterForm(
        tester,
        email: 'new_retailer@email.com',
        fullName: 'New Store Owner',
        businessType: 'Pet Shop',
        phone: '8123456789',
        password: 'password123',
        confirmPassword: 'password456',
      );

      await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
      await tester.tap(find.byKey(const Key('createAccountButton')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
