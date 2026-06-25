import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 1 - Retail & CS Management', () {
    testWidgets('TC-31: Admin lihat daftar CS', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);
      await goToStaffManagement(tester);

      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('cs@email.com'), findsOneWidget);
      expect(find.text('AKTIF'), findsOneWidget);
    });

    testWidgets('TC-32: Admin ubah status CS', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);
      await goToStaffManagement(tester);

      // Verify currently active
      expect(find.text('AKTIF'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Tap confirmation
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();

      // Verify status changed to INACTIVE
      expect(find.text('NONAKTIF'), findsOneWidget);
    });

    testWidgets('TC-33: Admin tambah CS baru', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);
      await goToStaffManagement(tester);

      // Tap add icon
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Fill Form
      await tester.enterText(find.widgetWithText(TextFormField, 'Masukkan nama lengkap'), 'New CS Member');
      await tester.enterText(find.widgetWithText(TextFormField, 'Masukkan alamat email'), 'newcs@email.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Masukkan password'), '12345678');
      await tester.enterText(find.widgetWithText(TextFormField, 'Masukkan nomor telepon'), '08988888888');
      await tester.pumpAndSettle();

      // Tap Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Customer Support'));
      await tester.pumpAndSettle();

      // Verify added CS is in the list
      expect(find.text('New CS Member'), findsOneWidget);
    });

    testWidgets('TC-34: Admin lihat daftar retailer', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToRetailerManagement(tester);

      expect(find.byKey(const Key('searchField')), findsOneWidget);
      expect(find.text('Total Retailer'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Nonaktif'), findsOneWidget);
    });

    testWidgets('TC-35: Admin search retailer', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToRetailerManagement(tester);

      // Initial active retailer Toko Retailer is visible
      expect(find.text('Toko Retailer'), findsOneWidget);

      // Search for something else
      await tester.enterText(find.byKey(const Key('searchField')), 'Nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('Toko Retailer'), findsNothing);

      // Clear search
      await tester.enterText(find.byKey(const Key('searchField')), '');
      await tester.pumpAndSettle();
      expect(find.text('Toko Retailer'), findsOneWidget);
    });

    testWidgets('TC-36: Admin filter retailer', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToRetailerManagement(tester);

      // Default is Active filter: Toko Retailer is shown, Toko Inactive is not
      expect(find.text('Toko Retailer'), findsOneWidget);
      expect(find.text('Toko Inactive'), findsNothing);

      // Tap Inactive filter button
      await tester.tap(find.text('Nonaktif'));
      await tester.pumpAndSettle();

      expect(find.text('Toko Retailer'), findsNothing);
      expect(find.text('Toko Inactive'), findsOneWidget);
    });

    testWidgets('TC-37: Admin ubah status retailer', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToRetailerManagement(tester);

      // Verify active retailer is visible
      expect(find.text('Toko Retailer'), findsOneWidget);

      // Open Select dropdown
      await tester.tap(find.text('Pilih').first);
      await tester.pumpAndSettle();

      // Tap Inactive
      await tester.tap(find.text('Nonaktif').last);
      await tester.pumpAndSettle();

      // Tap Yes on dialog
      await tester.tap(find.text('Ya'));
      await tester.pumpAndSettle();

      // Since they are now inactive, and the default filter is Active, they should disappear from the active list
      expect(find.text('Toko Retailer'), findsNothing);
    });
  });
}
