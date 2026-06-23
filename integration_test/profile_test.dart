import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 1 - Profile Management', () {
    testWidgets('TC-22: Retailer lihat profil', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      expect(find.text('Toko Retailer'), findsOneWidget);
      expect(find.textContaining('#KNY'), findsOneWidget);
      expect(find.text('rt@email.com'), findsOneWidget);
      expect(find.text('08234567890'), findsOneWidget);
      expect(find.text('Pet Shop').first, findsOneWidget);
      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);
    });

    testWidgets('TC-23: Retailer edit profil valid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), 'Toko Baru');
      await tester.enterText(find.byKey(const Key('contactField')), '08999999999');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('TC-24: Retailer edit nama kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Business Name is required'), findsOneWidget);
    });

    testWidgets('TC-25: Retailer edit contact kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('contactField')), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Contact is required'), findsOneWidget);
    });

    testWidgets('TC-26: Admin lihat profil', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      expect(find.text('Distributor Admin'), findsOneWidget);
      expect(find.text('Distributor'), findsOneWidget);
      expect(find.textContaining('#DS'), findsOneWidget);
      expect(find.text('08123456789'), findsOneWidget);
      expect(find.text('Staff Management'), findsOneWidget);
    });

    testWidgets('TC-27: Admin edit profil valid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), 'Admin Baru');
      await tester.enterText(find.byKey(const Key('contactField')), '08111111111');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('TC-28: Admin edit nama kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Business Name is required'), findsOneWidget);
    });

    testWidgets('TC-29: Admin edit contact kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('contactField')), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Contact is required'), findsOneWidget);
    });

    testWidgets('TC-30: CS lihat profil', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'cs@email.com', '12345678');
      await goToProfile(tester);

      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('Customer Service'), findsOneWidget);
      expect(find.textContaining('#CS'), findsOneWidget);
      expect(find.text('Technical Support'), findsOneWidget);
      expect(find.text('08345678901'), findsOneWidget);
      expect(find.text('Total Tickets'), findsOneWidget);
    });
  });
}
