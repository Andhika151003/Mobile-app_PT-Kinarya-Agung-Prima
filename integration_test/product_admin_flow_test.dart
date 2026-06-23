import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Product Admin UI Automation (Black Box)', () {
    // =========================================================================
    // INTEGRATION TEST FLOWS COVERED IN THIS FILE:
    // - TC - 64 : Admin Menampilkan daftar produk
    // - TC - 65 : Admin Tambah produk baru — data valid
    // - TC - 70 : Admin Update stok produk secara manual
    // =========================================================================

    testWidgets('Complete Flow: Login, Add Product, and Update Stock', (
      WidgetTester tester,
    ) async {
      // 1. Launch the Application (main returns void, so we call it sync)
      app.main();
      await tester.pump();

      // Wait until either the Login Screen or the Admin Dashboard (Products navigation tab) is loaded
      bool isLoginScreen = false;
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byKey(const Key('login_email_field')).evaluate().isNotEmpty) {
          isLoginScreen = true;
          break;
        }
        if (find.text('Products').evaluate().isNotEmpty) {
          break;
        }
      }

      if (isLoginScreen) {
        // Verify Login Screen widgets
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);

        // 2. Perform Login with Admin Credentials
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'admin@gmail.com',
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'admin123',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('login_submit_btn')));
        await tester.pumpAndSettle();

        // Wait a few seconds for Firebase Auth session and data synchronization
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }

      // 3. Navigate to Products Tab
      // [TC - 64 : Admin Menampilkan daftar produk]
      // Tap the 'Products' item in BottomNavigationBar
      final productsTabFinder = find.text('Products');
      expect(productsTabFinder, findsOneWidget);
      await tester.tap(productsTabFinder);
      await tester.pumpAndSettle();

      // Wait for products to load from Firestore stream
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 4. Flow 1: Add a New Product
      // [TC - 65 : Admin Tambah produk baru — data valid]
      final fabFinder = find.byKey(const Key('add_product_fab'));
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Fill in Basic Information
      await tester.enterText(
        find.byKey(const Key('add_product_name_field')),
        'Automated Test Soap ${DateTime.now().millisecondsSinceEpoch}',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_sku_field')),
        'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      );
      await tester.pumpAndSettle();

      // Select Category
      final categoryDropdownFinder = find.byKey(
        const Key('add_product_category_dropdown'),
      );
      await tester.tap(categoryDropdownFinder);
      await tester.pumpAndSettle();

      final categoryItemFinder = find.text('Beauty Care').last;
      await tester.tap(categoryItemFinder);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_brand_field')),
        'AutoBrand',
      );
      await tester.pumpAndSettle();

      // Pricing & MOQ
      await tester.enterText(
        find.byKey(const Key('add_product_price_field')),
        '25000',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_moq_field')),
        '2',
      );
      await tester.pumpAndSettle();

      // Inventory
      await tester.enterText(
        find.byKey(const Key('add_product_stock_field')),
        '50',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_low_stock_field')),
        '5',
      );
      await tester.pumpAndSettle();

      // Description
      await tester.enterText(
        find.byKey(const Key('add_product_desc_field')),
        'This is a product created automatically by the Black Box UI Automation Test.',
      );
      await tester.pumpAndSettle();

      // Shipping & Dimensions
      await tester.enterText(
        find.byKey(const Key('add_product_weight_field')),
        '0.5',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_length_field')),
        '15',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_width_field')),
        '10',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('add_product_height_field')),
        '5',
      );
      await tester.pumpAndSettle();

      // Save the Product
      final saveBtnFinder = find.byKey(const Key('add_product_save_btn'));
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      // Wait for the firebase upload/add request to complete
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 5. Flow 2: Add Stock to an Existing Product
      // [TC - 70 : Admin Update stok produk secara manual]
      // Find the first "Add Stock" button visible in the list
      final addStockButtonFinder = find
          .byWidgetPredicate(
            (widget) =>
                widget is GestureDetector &&
                widget.key != null &&
                widget.key.toString().contains('add_stock_button_'),
          )
          .first;

      expect(addStockButtonFinder, findsOneWidget);
      
      // Ensure the widget is visible in viewport before tapping
      await tester.ensureVisible(addStockButtonFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(addStockButtonFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Add Stock Dialog is displayed
      expect(find.text('Add Stock'), findsOneWidget);

      // Increment stock 3 times with settling in between to avoid pointer clashes
      final incrementBtnFinder = find.byKey(const Key('add_stock_increment'));
      
      await tester.tap(incrementBtnFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      
      await tester.tap(incrementBtnFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      
      await tester.tap(incrementBtnFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      // Save the Stock
      final saveStockBtnFinder = find.byKey(const Key('add_stock_save'));
      await tester.tap(saveStockBtnFinder);
      await tester.pumpAndSettle();

      // Wait for database update to execute
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Success SnackBar should have appeared and dialog closed
      expect(find.text('Add Stock'), findsNothing);
    });
  });
}
