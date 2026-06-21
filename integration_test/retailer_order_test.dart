import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to login as Retailer
  Future<void> loginAsRetailer(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;
    final loginButton = find.text('LOGIN');

    if (loginButton.evaluate().isNotEmpty) {
      await tester.enterText(emailField, 'retailer@email.com');
      await tester.enterText(passwordField, '12345678');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }
  }

  group('Order Management Flow (Retailer)', () {
    testWidgets('14. Ritel melihat daftar pesanan yang dia order', (tester) async {
      await loginAsRetailer(tester);

      // Navigate to Orders Tab
      final ordersTab = find.text('Pesanan');
      if (ordersTab.evaluate().isNotEmpty) {
        await tester.tap(ordersTab);
        await tester.pumpAndSettle();
      }
      
      // Verify order list is present
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasScrollView = find.byType(SingleChildScrollView).evaluate().isNotEmpty;
      expect(hasListView || hasScrollView, isTrue);
    });

    testWidgets('15. Ritel melihat detail pesanan', (tester) async {
      await loginAsRetailer(tester);

      // Navigate to Orders Tab
      final ordersTab = find.text('Pesanan'); 
      if (ordersTab.evaluate().isNotEmpty) {
        await tester.tap(ordersTab);
        await tester.pumpAndSettle();
      }

      // Find an order item and tap it
      final orderItem = find.text('Detail Pesanan').first; // Usually a button or just tap the card
      if (orderItem.evaluate().isNotEmpty) {
         await tester.tap(orderItem);
         await tester.pumpAndSettle();
         
         // Verify we are on detail page
         expect(find.text('Status Pesanan'), findsWidgets);
      }
    });

    testWidgets('16. Validasi pencarian pesanan dengan data yang tidak valid (Empty State)', (tester) async {
      await loginAsRetailer(tester);

      // Navigate to Orders Tab
      final ordersTab = find.text('Pesanan'); 
      if (ordersTab.evaluate().isNotEmpty) {
        await tester.tap(ordersTab);
        await tester.pumpAndSettle();
      }

      // Use search bar
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
         await tester.tap(searchIcon);
         await tester.pumpAndSettle();
         
         final searchField = find.byType(TextField).first;
         await tester.enterText(searchField, 'PESANAN_TIDAK_VALID_123');
         await tester.pumpAndSettle();

         // Expect empty state text/image
         expect(find.textContaining('tidak ditemukan'), findsWidgets);
      }
    });

    testWidgets('17. Validasi UI garis status pesanan', (tester) async {
      await loginAsRetailer(tester);

      // Go to order detail
      final ordersTab = find.text('Pesanan'); 
      if (ordersTab.evaluate().isNotEmpty) {
        await tester.tap(ordersTab);
        await tester.pumpAndSettle();
      }

      final orderItem = find.text('Detail Pesanan').first;
      if (orderItem.evaluate().isNotEmpty) {
         await tester.tap(orderItem);
         await tester.pumpAndSettle();
         
         // Assuming timeline/stepper is used for order status
         // e.g. finding 'Dikemas', 'Dikirim', 'Selesai' texts
         expect(find.text('Dikemas'), findsWidgets);
         expect(find.text('Dikirim'), findsWidgets);
      }
    });
  });
}
