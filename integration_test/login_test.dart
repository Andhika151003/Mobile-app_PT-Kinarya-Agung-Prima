@Timeout(Duration(minutes: 5))

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 1 - Login & Forgot Password', () {
    testWidgets('TC-1: Login Admin', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      
      expect(find.text('Ringkasan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-2: Login Retailer', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');

      expect(find.text('Pesanan Terbaru'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-3: Login CS', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'cs@email.com', '12345678');

      expect(find.text('Komplain Terbaru'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-4: Login dengan akun dinonaktifkan', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'inactive@email.com', '12345678');
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && 
            (widget.data == 'Account Deactivated' || widget.data == 'Akun Dinonaktifkan')
        ),
        findsWidgets,
      );
      
      // Close dialog
      final closeButton = find.text('Tutup');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-5: Login dengan email/password salah', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      // Wrong password
      await loginAs(tester, 'ad@email.com', 'wrong_pass');
      expect(find.text('Kata sandi salah'), findsWidgets);

      // Reset fields
      await tester.enterText(find.byKey(const Key('login_email_field')), '');
      await tester.enterText(find.byKey(const Key('login_password_field')), '');
      await tester.pumpAndSettle();

      // Wrong email
      await loginAs(tester, 'nonexistent@email.com', '12345678');
      expect(find.text('Email tidak ditemukan'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-6: Login dengan email kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, '', '12345678');
      expect(find.text('Email wajib diisi'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-7: Login dengan password kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '');
      expect(find.text('Password wajib diisi'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-38: Forgot Password email terdaftar', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      // Tap Forgot Password link
      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(find.byKey(const Key('forgotPasswordEmailField')), 'ad@email.com');
      await tester.tap(find.byKey(const Key('sendResetLinkButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email Terkirim'), findsOneWidget);

      // Back to Login
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Kembali ke Login'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-39: Forgot Password email tidak terdaftar', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('forgotPasswordEmailField')), 'notregistered@email.com');
      await tester.tap(find.byKey(const Key('sendResetLinkButton')));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada pengguna dengan email ini.'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-40: Forgot Password format email invalid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('forgotPasswordEmailField')), 'invalid-email');
      await tester.tap(find.byKey(const Key('sendResetLinkButton')));
      await tester.pumpAndSettle();

      expect(find.text('Harap masukkan alamat email yang valid'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-41: Forgot Password email kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('forgotPasswordEmailField')), '');
      await tester.tap(find.byKey(const Key('sendResetLinkButton')));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
