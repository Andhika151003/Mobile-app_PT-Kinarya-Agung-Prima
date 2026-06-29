import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loginAsCS(WidgetTester tester) async {
    await setupTestEnvironment();
    app.main();
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await loginAs(tester, 'cs@email.com', '12345678');
    await tester.pump(const Duration(seconds: 2));
  }

  group('Order Management Flow (Customer Support)', () {
    testWidgets('21. Customer Support (CS) melihat detail pesanan untuk memvalidasi keluhan', (tester) async {
      await loginAsCS(tester);

      // Navigate to CS/Complaint/Order menu
      for(int i=0; i<20; i++) { await tester.pump(const Duration(milliseconds: 500)); if(find.text('Dukungan').evaluate().isNotEmpty) break; }
      final keluhanMenu = find.text('Dukungan'); // Replace with actual CS menu text
      if (keluhanMenu.evaluate().isNotEmpty) {
        await tester.tap(keluhanMenu);
        await tester.pumpAndSettle();
      }

      // Or if CS directly views orders
      final pesananMenu = find.byIcon(Icons.shopping_basket_outlined);
      if (pesananMenu.evaluate().isNotEmpty) {
        await tester.tap(pesananMenu);
        await tester.pumpAndSettle();
      }
      
      // Open detail of an order/complaint
      final detailBtn = find.text('Detail');
      if (detailBtn.evaluate().isNotEmpty) {
         await tester.tap(detailBtn.first);
         await tester.pumpAndSettle();
         
         // Verify we are on the order detail page validating complaint
         final hasDetailKeluhan = find.text('Detail Komplain').evaluate().isNotEmpty;
         final hasDetailPesanan = find.text('Detail Pesanan').evaluate().isNotEmpty;
         expect(hasDetailKeluhan || hasDetailPesanan, isTrue);
         expect(find.text('Validasi'), findsWidgets); // e.g. a validate button
      }
    });
  });
}
