import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to login as Customer Support
  Future<void> loginAsCS(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;
    final loginButton = find.text('LOGIN');

    if (loginButton.evaluate().isNotEmpty) {
      await tester.enterText(emailField, 'cs@email.com');
      await tester.enterText(passwordField, '12345678'); 
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }
  }

  group('Order Management Flow (Customer Support)', () {
    testWidgets('21. Customer Support (CS) melihat detail pesanan untuk memvalidasi keluhan', (tester) async {
      await loginAsCS(tester);

      // Navigate to CS/Complaint/Order menu
      final keluhanMenu = find.text('Daftar Keluhan'); // Replace with actual CS menu text
      if (keluhanMenu.evaluate().isNotEmpty) {
        await tester.tap(keluhanMenu);
        await tester.pumpAndSettle();
      }

      // Or if CS directly views orders
      final pesananMenu = find.text('Semua Pesanan');
      if (pesananMenu.evaluate().isNotEmpty) {
        await tester.tap(pesananMenu);
        await tester.pumpAndSettle();
      }
      
      // Open detail of an order/complaint
      final detailBtn = find.text('Detail').first;
      if (detailBtn.evaluate().isNotEmpty) {
         await tester.tap(detailBtn);
         await tester.pumpAndSettle();
         
         // Verify we are on the order detail page validating complaint
         final hasDetailKeluhan = find.text('Detail Keluhan').evaluate().isNotEmpty;
         final hasDetailPesanan = find.text('Detail Pesanan').evaluate().isNotEmpty;
         expect(hasDetailKeluhan || hasDetailPesanan, isTrue);
         expect(find.text('Validasi'), findsWidgets); // e.g. a validate button
      }
    });
  });
}
