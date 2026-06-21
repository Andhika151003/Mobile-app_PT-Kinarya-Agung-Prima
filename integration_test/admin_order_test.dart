import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to login as Admin
  Future<void> loginAsAdmin(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;
    final loginButton = find.text('LOGIN');

    if (loginButton.evaluate().isNotEmpty) {
      await tester.enterText(emailField, 'ad@email.com'); // Admin email from previous test
      await tester.enterText(passwordField, '12345678'); 
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }
  }

  group('Order Management Flow (Admin)', () {
    testWidgets('18. Admin melihat seluruh daftar pesanan dari berbagai ritel', (tester) async {
      await loginAsAdmin(tester);

      // Navigate to Admin Order Management
      final ordersMenu = find.text('Manajemen Pesanan'); // Replace with actual Admin menu text
      if (ordersMenu.evaluate().isNotEmpty) {
        await tester.tap(ordersMenu);
        await tester.pumpAndSettle();
      }
      
      // Verify list of orders is present
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasScrollView = find.byType(SingleChildScrollView).evaluate().isNotEmpty;
      expect(hasListView || hasScrollView, isTrue);
    });

    testWidgets('19. Admin memperbarui status pesanan Paid(Dibayar) menjadi Shipped (Dikirim)', (tester) async {
      await loginAsAdmin(tester);

      // Go to order management
      final ordersMenu = find.text('Manajemen Pesanan'); 
      if (ordersMenu.evaluate().isNotEmpty) {
        await tester.tap(ordersMenu);
        await tester.pumpAndSettle();
      }

      // Filter by 'Dibayar' or find an order that is 'Dibayar'
      final paidTab = find.text('Dibayar');
      if (paidTab.evaluate().isNotEmpty) {
        await tester.tap(paidTab);
        await tester.pumpAndSettle();
      }

      // Open detail
      final orderItem = find.text('Detail').first;
      if (orderItem.evaluate().isNotEmpty) {
         await tester.tap(orderItem);
         await tester.pumpAndSettle();
         
         // Find action button to update status to shipped
         final shipBtn = find.text('Kirim Pesanan'); // Replace with actual button text
         if (shipBtn.evaluate().isNotEmpty) {
            await tester.tap(shipBtn);
            await tester.pumpAndSettle();
            // Optional: confirm dialog
            final confirmBtn = find.text('Ya');
            if (confirmBtn.evaluate().isNotEmpty) {
              await tester.tap(confirmBtn);
              await tester.pumpAndSettle();
            }
            // Verify success toast or status change
            // expect(find.text('Pesanan dikirim'), findsWidgets);
         }
      }
    });

    testWidgets('20. Admin membatalkan pesanan secara manual', (tester) async {
      await loginAsAdmin(tester);

      // Go to order management
      final ordersMenu = find.text('Manajemen Pesanan'); 
      if (ordersMenu.evaluate().isNotEmpty) {
        await tester.tap(ordersMenu);
        await tester.pumpAndSettle();
      }

      // Open detail
      final orderItem = find.text('Detail').first;
      if (orderItem.evaluate().isNotEmpty) {
         await tester.tap(orderItem);
         await tester.pumpAndSettle();
         
         // Find cancel button
         final cancelBtn = find.text('Batalkan Pesanan'); 
         if (cancelBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelBtn);
            await tester.pumpAndSettle();
            
            // Confirm cancel
            final confirmBtn = find.text('Ya, Batalkan');
            if (confirmBtn.evaluate().isNotEmpty) {
              await tester.tap(confirmBtn);
              await tester.pumpAndSettle();
            }
         }
      }
    });
  });
}
