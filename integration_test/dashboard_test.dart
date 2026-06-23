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

      await loginAs(tester, 'ad@email.com', '12345678');

      expect(find.text('Total Sales'), findsOneWidget);
      expect(find.text('Orders').first, findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Active Promotions'), findsOneWidget);
      expect(find.text('My Retailers'), findsOneWidget);
    });

    testWidgets('TC-20: CS Dashboard checks', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'cs@email.com', '12345678');

      expect(find.text('Open Complaints'), findsOneWidget);
      expect(find.text('Resolved Today'), findsOneWidget);
      expect(find.text('Recent Complaints'), findsOneWidget);
    });

    testWidgets('TC-21: Retailer Homepage checks', (tester) async {
      await setupTestEnvironment();
      app.main();
      await tester.pumpAndSettle();

      await loginAs(tester, 'rt@email.com', '12345678');

      expect(find.textContaining('Selamat Datang'), findsOneWidget);
      expect(find.text('Recent Orders'), findsOneWidget);
      expect(find.text('Recommended for You'), findsOneWidget);
    });
  });
}
