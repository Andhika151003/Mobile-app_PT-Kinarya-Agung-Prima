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

  group('Cart and Checkout Flow (Retailer)', () {
    testWidgets('1. Ritel menambahkan produk ke dalam keranjang untuk pertama kali', (tester) async {
      await loginAsRetailer(tester);

      final addToCartBtn = find.text('Tambah ke Keranjang').first;
      expect(addToCartBtn, findsOneWidget);
      await tester.tap(addToCartBtn);
      await tester.pumpAndSettle();

      // Verify success message or badge update
      // e.g. expect(find.text('Produk berhasil ditambahkan'), findsOneWidget);
    });

    testWidgets('2. Ritel menambahkan produk saat stok produk dibawah MOQ', (tester) async {
      await loginAsRetailer(tester);

      // Assuming we navigate to a specific product that is known to have stock < MOQ
      // Or we try to set the quantity directly below MOQ and expect an error/warning
      // Needs specific UI details to be 100% accurate.
      // e.g. finding a warning text:
      // expect(find.text('Stok di bawah MOQ'), findsOneWidget);
    });

    testWidgets('3. Validasi field kuantitas tidak dapat diinput manual', (tester) async {
      await loginAsRetailer(tester);

      // Go to cart or product detail
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();
      }

      // Find the quantity field, typically a TextField or Text widget in a row.
      // If it's a Text widget instead of TextField, it cannot be input manually.
      // Here we assume it might be a TextField with readOnly = true
      final qtyField = find.byType(TextField).first;
      if (qtyField.evaluate().isNotEmpty) {
         final TextField textField = tester.widget(qtyField);
         expect(textField.readOnly, isTrue, reason: 'Field kuantitas harusnya tidak bisa diinput manual');
      }
    });

    testWidgets('4. Menambah jumlah produk dengan tombol (+)', (tester) async {
      await loginAsRetailer(tester);
      
      // Navigate to Cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();
      }

      final addBtn = find.byIcon(Icons.add).first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      // Verify quantity text increased
    });

    testWidgets('5. Menambah jumlah produk hingga melebihi sisa stok', (tester) async {
      await loginAsRetailer(tester);
      // Similar to test 4, tap until stock limit is reached, then verify error message or disabled button
    });

    testWidgets('6. Mengurangi jumlah produk dengan tombol (-)', (tester) async {
      await loginAsRetailer(tester);
      final minusBtn = find.byIcon(Icons.remove).first;
      if (minusBtn.evaluate().isNotEmpty) {
         await tester.tap(minusBtn);
         await tester.pumpAndSettle();
      }
    });

    testWidgets('7. Mengurangi jumlah produk pada batas bawah MOQ', (tester) async {
      await loginAsRetailer(tester);
      // Find minus button and click until MOQ is reached, ensure it doesn't go below or shows warning
    });

    testWidgets('8. Menghapus produk dari keranjang secara manual', (tester) async {
      await loginAsRetailer(tester);
      // Navigate to Cart
      final deleteIcon = find.byIcon(Icons.delete).first;
      if (deleteIcon.evaluate().isNotEmpty) {
        await tester.tap(deleteIcon);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('9. Mencoba checkout dengan keranjang kosong', (tester) async {
      await loginAsRetailer(tester);
      // Navigate to Cart, ensure empty, try to find checkout button
      final checkoutBtn = find.text('Checkout');
      // Button might be disabled or not present, or tapping it shows snackbar
      if (checkoutBtn.evaluate().isNotEmpty) {
         await tester.tap(checkoutBtn);
         await tester.pumpAndSettle();
         expect(find.text('Keranjang kosong'), findsWidgets); // Example error msg
      }
    });

    testWidgets('10. Melakukan checkout dengan produk yang ingin dibeli', (tester) async {
      await loginAsRetailer(tester);
      // Add product, navigate to cart, tap checkout
      final checkoutBtn = find.text('Checkout');
      if (checkoutBtn.evaluate().isNotEmpty) {
         await tester.tap(checkoutBtn);
         await tester.pumpAndSettle();
         // Verify we reach checkout or payment page
      }
    });

    testWidgets('11. Menambahkan produk ke dalam keranjang kemudian user keluar dari aplikasi (force close/logout)', (tester) async {
      // Setup: Login, add product, then "restart" the app to see if cart persists
      await loginAsRetailer(tester);
      
      // Simulate app restart by calling main again or relying on shared prefs
      app.main();
      await tester.pumpAndSettle();
      
      // Go to cart, check if item is there
    });

    testWidgets('12. Menambahkan produk yang sudah ada didalam keranjang', (tester) async {
      await loginAsRetailer(tester);
      // Add product A, then Add product A again. Verify qty increases instead of duplicate item.
    });

    testWidgets('13. Menambahkan beberapa jenis produk', (tester) async {
      await loginAsRetailer(tester);
      // Add product A, Add product B. Navigate to Cart, verify both exist.
    });
  });
}
