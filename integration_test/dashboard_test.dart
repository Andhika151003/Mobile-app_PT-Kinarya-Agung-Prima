import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 1 - Dashboard', () {
    testWidgets('TC-19: Admin Dashboard checks', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await loginAs(tester, 'ad@email.com', '12345678');
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Total Penjualan'), findsOneWidget);
      expect(find.text('Pesanan').first, findsOneWidget);
      expect(find.text('Pelanggan'), findsOneWidget);
      expect(find.text('Promosi Aktif'), findsOneWidget);
      expect(find.text('Retailer Saya'), findsOneWidget);

      // Test navigation to Manage Retail (Retailer Management)
      final viewAllFinder = find.text('Lihat Semua');
      expect(viewAllFinder, findsOneWidget);
      await tester.tap(viewAllFinder);
      await tester.pumpAndSettle();

      expect(find.text('Total Retailer'), findsOneWidget);

      // Navigate back to Dashboard
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        final iconBack = find.byIcon(Icons.arrow_back);
        if (iconBack.evaluate().isNotEmpty) {
          await tester.tap(iconBack);
        } else {
          await tester.pageBack();
        }
      }
      await tester.pumpAndSettle();
    });

    testWidgets('TC-20: CS Dashboard checks', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await loginAs(tester, 'cs@email.com', '12345678');
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Komplain Terbuka'), findsOneWidget);
      expect(find.text('Diselesaikan Hari Ini'), findsOneWidget);
      expect(find.text('Komplain Terbaru'), findsOneWidget);
      
      // Tunggu stream data load
      await tester.pump(const Duration(seconds: 2));
      
      // Tap pada dummy complaint yang baru ditambahkan
      // final complaintTitle = find.text('Barang Rusak');
      // expect(complaintTitle, findsWidgets); // findsWidgets karena bisa jadi lebih dari 1 jika dummy lain ada
      // await tester.tap(complaintTitle.first);
      // await tester.pumpAndSettle();
      
      // await tester.pump(const Duration(seconds: 2));
      
      // // Verifikasi berhasil masuk ke halaman detail
      // expect(find.text('Complaint Detail'), findsOneWidget);
      
      // await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TC-21: Retailer Homepage checks', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await loginAs(tester, 'rt@email.com', '12345678');
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Selamat Datang'), findsOneWidget);
      expect(find.text('Pesanan Terbaru'), findsOneWidget);
      expect(find.text('Rekomendasi untuk Anda'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
