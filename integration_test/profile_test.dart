@Timeout(Duration(minutes: 5))

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
      expect(find.text('Total Pesanan'), findsOneWidget);
      expect(find.text('Total Pengeluaran'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-23: Retailer edit profil valid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), 'Toko Baru');
      await tester.enterText(find.byKey(const Key('contactField')), '08999999999');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Profil berhasil diperbarui!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-24: Retailer edit nama kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), '');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nama Usaha wajib diisi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-25: Retailer edit contact kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('contactField')), '');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kontak wajib diisi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
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
      expect(find.text('Manajemen Staf'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-27: Admin edit profil valid', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), 'Admin Baru');
      await tester.enterText(find.byKey(const Key('contactField')), '08111111111');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Profil Admin berhasil diperbarui!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-28: Admin edit nama kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('businessNameField')), '');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nama Usaha wajib diisi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-29: Admin edit contact kosong', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await goToProfile(tester);

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('contactField')), '');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kontak wajib diisi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-30: CS lihat profil', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'cs@email.com', '12345678');
      await goToProfile(tester);

      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('Layanan Pelanggan'), findsOneWidget);
      expect(find.textContaining('#CS'), findsOneWidget);
      expect(find.text('Dukungan Teknis'), findsOneWidget);
      expect(find.text('08345678901'), findsOneWidget);
      expect(find.text('Total Tiket'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
