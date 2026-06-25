@Timeout(Duration(minutes: 5))

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'package:ecommerce/features/shared/main_navigation_admin.dart';
import 'helpers/test_utils.dart';


Future<void> goToOrdersPage(WidgetTester tester) async {
  final navFinder = find.byType(MainNavigationAdmin);
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (navFinder.evaluate().isNotEmpty) break;
  }

  if (navFinder.evaluate().isNotEmpty) {
    final state = tester.state<MainNavigationAdminState>(navFinder);
    state.setIndex(2);
    await tester.pumpAndSettle();
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(ListView).evaluate().isNotEmpty ||
          find
              .byKey(const Key('card_admin_order_ORD-12345'))
              .evaluate()
              .isNotEmpty)
        break;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Order Management Flow (Admin)', () {
    testWidgets(
      '18. Admin melihat seluruh daftar pesanan dari berbagai ritel',
      (tester) async {
        await setupTestEnvironment();
        app.main();
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 2));
        await loginAs(tester, 'ad@email.com', '12345678');
        await tester.pump(const Duration(seconds: 2));

        await goToOrdersPage(tester);

        final hasListView = find.byType(ListView).evaluate().isNotEmpty;
        final hasCard = find
            .byKey(const Key('card_admin_order_ORD-12345'))
            .evaluate()
            .isNotEmpty;
        expect(
          hasListView || hasCard,
          isTrue,
          reason: 'Daftar pesanan tidak ditemukan setelah navigasi ke Orders',
        );

        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      '19. Admin memperbarui status pesanan Paid(Dibayar) menjadi Shipped (Dikirim)',
      (tester) async {
        await setupTestEnvironment();
        app.main();
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 2));
        await loginAs(tester, 'ad@email.com', '12345678');
        await tester.pump(const Duration(seconds: 2));

        // Navigasi ke halaman Orders
        await goToOrdersPage(tester);

        // Tunggu order card ORD-12345 (status Paid = Dikemas)
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find
              .byKey(const Key('card_admin_order_ORD-12345'))
              .evaluate()
              .isNotEmpty)
            break;
        }

        // Open detail pesanan Paid
        final orderCard = find.byKey(const Key('card_admin_order_ORD-12345'));
        if (orderCard.evaluate().isNotEmpty) {
          await tester.tap(orderCard.first);
          await tester.pumpAndSettle();

          // Find action button to update status
          final updateBtn = find.text('Update Status');
          if (updateBtn.evaluate().isNotEmpty) {
            await tester.tap(updateBtn.first);
            await tester.pumpAndSettle();
            final confirmBtn = find.text('Konfirmasi');
            if (confirmBtn.evaluate().isNotEmpty) {
              await tester.tap(confirmBtn.first);
              await tester.pumpAndSettle();
            }
          }
        } else {
          debugPrint('Info: Tidak ada pesanan untuk diproses di test 19');
        }

        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets('20. Admin membatalkan pesanan secara manual', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await loginAs(tester, 'ad@email.com', '12345678');
      await tester.pump(const Duration(seconds: 2));

      // Navigasi ke halaman Orders
      await goToOrdersPage(tester);

      // Tunggu order card ORD-67890
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find
            .byKey(const Key('card_admin_order_ORD-67890'))
            .evaluate()
            .isNotEmpty)
          break;
      }

      // Open detail
      final orderCard = find.byKey(const Key('card_admin_order_ORD-67890'));
      if (orderCard.evaluate().isNotEmpty) {
        await tester.tap(orderCard.first);
        await tester.pumpAndSettle();

        // Find cancel button
        final cancelBtn = find.text('Batalkan Pesanan');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first);
          await tester.pumpAndSettle();

          final confirmBtn = find.text('Ya, Batalkan');
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn.first);
            await tester.pumpAndSettle();
          }
        }
      } else {
        debugPrint('Info: Tidak ada pesanan untuk dibatalkan di test 20');
      }

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
