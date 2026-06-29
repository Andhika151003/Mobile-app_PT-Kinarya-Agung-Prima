import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI ADMIN
  // ───────────────────────────────────────────────────────────
  // View  : NotificationAdminView     → title 'Notifikasi Admin'
  // Ikon  : Icons.shopping_cart_outlined (order)
  //         Icons.error_outline          (complaint)
  //         Icons.settings_outlined      (system)
  // Empty : 'Tidak ada notifikasi admin'
  // Action: 'Baca Semua'
  // ───────────────────────────────────────────────────────────

  group('Admin Notifikasi', () {
    testWidgets('1. Admin login dan buka halaman notifikasi', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_none_outlined);
      expect(notifIcon, findsOneWidget);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Notifikasi Admin'), findsOneWidget);
      expect(find.text('Baca Semua'), findsOneWidget);
    });

    testWidgets('2. Notifikasi admin tampilkan ikon sesuai tipe atau empty state', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_none_outlined);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final hasOrder = find.byIcon(Icons.shopping_cart_outlined).evaluate().isNotEmpty;
      final hasComplaint = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
      final isEmpty = find.text('Tidak ada notifikasi admin').evaluate().isNotEmpty;

      if (isEmpty) {
        expect(find.text('Tidak ada notifikasi admin'), findsOneWidget);
      } else {
        expect(hasOrder || hasComplaint, isTrue,
            reason: 'Seharusnya ada notifikasi (order/complaint) atau empty state');
      }
    });

    testWidgets('3. Admin tombol Mark All Read bisa ditekan', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'ad@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_none_outlined);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final readAllButton = find.text('Baca Semua');
      if (readAllButton.evaluate().isNotEmpty) {
        await tester.tap(readAllButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      expect(find.text('Notifikasi Admin'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI USER / RETAILER
  // ───────────────────────────────────────────────────────────
  // View  : NotificationUserView      → title 'Notifikasi'
  // Ikon  : Icons.shopping_bag_outlined (order)
  //         Icons.local_offer_outlined  (promo)
  //         Icons.support_agent_outlined (complaint)
  // Empty : 'Belum ada notifikasi'
  // Action: 'Baca Semua'
  // ───────────────────────────────────────────────────────────

  group('User (Retailer) Notifikasi', () {
    testWidgets('4. User login dan buka halaman notifikasi', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_outlined);
      expect(notifIcon, findsOneWidget);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Baca Semua'), findsOneWidget);
    });

    testWidgets('5. Notifikasi user tampilkan ikon sesuai tipe atau empty state', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_outlined);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final hasOrder = find.byIcon(Icons.shopping_bag_outlined).evaluate().isNotEmpty;
      final hasPromo = find.byIcon(Icons.local_offer_outlined).evaluate().isNotEmpty;
      final hasComplaint = find.byIcon(Icons.support_agent_outlined).evaluate().isNotEmpty;
      final isEmpty = find.text('Belum ada notifikasi').evaluate().isNotEmpty;

      if (isEmpty) {
        expect(find.text('Belum ada notifikasi'), findsOneWidget);
      } else {
        expect(hasOrder || hasPromo || hasComplaint, isTrue,
            reason: 'Seharusnya ada notifikasi (order/promo/complaint) atau empty state');
      }
    });

    testWidgets('6. User tombol Baca Semua bisa ditekan', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');
      await tester.pumpAndSettle();

      final notifIcon = find.byIcon(Icons.notifications_outlined);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final readAllButton = find.text('Baca Semua');
      if (readAllButton.evaluate().isNotEmpty) {
        await tester.tap(readAllButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      expect(find.text('Notifikasi'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // NOTIFIKASI CS (Customer Service)
  // ───────────────────────────────────────────────────────────
  // Saat ini DashboardCsView BELUM memiliki ikon notifikasi
  // dan NotifCsView belum diimplementasikan di lib/.
  // Test di bawah akan login sebagai CS dan mencoba navigasi,
  // lalu melaporkan status infrastruktur CS Notifikasi.
  // ───────────────────────────────────────────────────────────

  group('CS Notifikasi', () {
    testWidgets('7. CS login dan verifikasi dashboard', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'cs@email.com', '12345678');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final welcomeFinder = find.textContaining('Selamat Datang');
      expect(welcomeFinder, findsOneWidget);

      final hasNotifIcon = find.byIcon(Icons.notifications_none_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.notifications_outlined).evaluate().isNotEmpty;

      if (!hasNotifIcon) {
        // ignore: avoid_print
        print('INFO: Dashboard CS belum memiliki ikon notifikasi. '
            'Perlu: (1) NotifCsController, (2) NotifCsView, (3) ikon di DashboardCsView');
      }
    });
  });
}