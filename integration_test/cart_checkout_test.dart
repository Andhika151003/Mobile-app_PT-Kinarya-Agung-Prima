@Timeout(Duration(minutes: 5))

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;
import 'package:ecommerce/core/firebase_provider.dart';
import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loginAsRetailer(WidgetTester tester) async {
    await setupTestEnvironment();
    app.main();
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 500));
    await loginAs(tester, 'rt@email.com', '12345678');
    await tester.pump(const Duration(milliseconds: 700));
  }

  // untuk menutup dialog promo di Dashboard
  Future<void> dismissPromoDialog(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final claimBtn = find.text('Klaim Penawaran Sekarang');
    if (claimBtn.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(claimBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  // untuk membersihkan snackbar agar tidak menghalangi tap
  Future<void> clearAllSnackbars(WidgetTester tester) async {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isNotEmpty) {
      ScaffoldMessenger.of(tester.element(scaffoldFinder.first)).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  // untuk navigasi ke tab Products catalog
  Future<void> goToProductsTab(WidgetTester tester) async {
    await dismissPromoDialog(tester);
    final productsTab = find.byIcon(Icons.storefront_outlined);
    if (productsTab.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(productsTab);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
    }
  }

  // untuk membuka halaman keranjang
  Future<void> goToCart(WidgetTester tester) async {
    await goToProductsTab(tester);
    final cartBtn = find.byKey(const Key('btn_cart_catalog'));
    if (cartBtn.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(cartBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
    } else {
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 700));
      }
    }
  }

  group('Cart and Checkout Flow (Retailer)', () {
    testWidgets('1. Ritel menambahkan produk ke dalam keranjang untuk pertama kali', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);

      final addToCartBtn = find.byKey(const Key('btn_add_to_cart_PROD-1'));
      expect(addToCartBtn, findsOneWidget);
      await tester.tap(addToCartBtn);
      await tester.pumpAndSettle();

      await clearAllSnackbars(tester);

      await goToCart(tester);
      expect(find.text('Whiskas'), findsWidgets);
    });

    testWidgets('2. Ritel menambahkan produk saat stok produk dibawah MOQ', (tester) async {
      await loginAsRetailer(tester);
      
      // Update PROD-2 moq di Firestore agar melebihi stock (stock = 5, moq = 10)
      final firestore = AppFirebase.firestore;
      await firestore.collection('products').doc('PROD-2').update({'moq': 10});
      
      await goToProductsTab(tester);

      // Tap add to cart on PROD-2 (Pedigree)
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-2')));
      await tester.pumpAndSettle();

      // Harus menampilkan SnackBar error
      expect(find.textContaining('tidak mencukupi'), findsOneWidget);
      await clearAllSnackbars(tester);

      // Buka Cart dan pastikan kosong
      await goToCart(tester);
      expect(find.text('Keranjang Masih Kosong'), findsOneWidget);
    });

    testWidgets('3. Validasi field kuantitas tidak dapat diinput manual', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);

      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();

      await clearAllSnackbars(tester);

      await goToCart(tester);

      // Kuantitas di CartView menggunakan widget Text, bukan TextField,
      // sehingga secara bawaan tidak dapat diinput secara manual.
      final qtyField = find.byType(TextField);
      expect(qtyField, findsNothing);
    });

    testWidgets('4. Menambah jumlah produk dengan tombol (+)', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);
      
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();

      await clearAllSnackbars(tester);

      await goToCart(tester);
      expect(find.text('1'), findsOneWidget);

      final addBtn = find.byKey(const Key('btn_add_qty_PROD-1'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('5. Menambah jumlah produk hingga melebihi sisa stok', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);
      
      // PROD-2 memiliki stock: 5
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-2')));
      await tester.pumpAndSettle();
      await clearAllSnackbars(tester);

      await goToCart(tester);
      expect(find.text('1'), findsOneWidget); // Default MOQ is 1

      final addBtn = find.byKey(const Key('btn_add_qty_PROD-2'));
      expect(addBtn, findsOneWidget);

      // Tap '+' 4 kali untuk mencapai stock limit 5
      for (int i = 0; i < 4; i++) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle();
      }
      expect(find.text('5'), findsOneWidget);

      // Tap '+' sekali lagi, harus tetap 5
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    // testWidgets('6. Mengurangi jumlah produk dengan tombol (-)', (tester) async {
    //   await loginAsRetailer(tester);
    //   await goToProductsTab(tester);
      
    //   await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
    //   await tester.pumpAndSettle();

    //   await clearAllSnackbars(tester);

    //   await goToCart(tester);
      
    //   // Tambah ke 2 terlebih dahulu
    //   await tester.tap(find.byKey(const Key('btn_add_qty_PROD-1')));
    //   await tester.pumpAndSettle();
    //   expect(find.text('2'), findsOneWidget);

    //   // Kurangi kembali ke 1
    //   final minusBtn = find.byKey(const Key('btn_min_qty_PROD-1'));
    //   expect(minusBtn, findsOneWidget);
    //   await tester.tap(minusBtn);
    //   await tester.pumpAndSettle();

    //   expect(find.text('1'), findsOneWidget);
    // });

    // testWidgets('7. Mengurangi jumlah produk pada batas bawah MOQ', (tester) async {
    //   await loginAsRetailer(tester);

    //   // Set PROD-1 moq = 3
    //   final firestore = AppFirebase.firestore;
    //   await firestore.collection('products').doc('PROD-1').update({'moq': 3});

    //   await goToProductsTab(tester);

    //   // Menambahkan ke keranjang (akan otomatis 3 karena moq = 3)
    //   await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
    //   await tester.pumpAndSettle();
    //   await clearAllSnackbars(tester);

    //   await goToCart(tester);
    //   expect(find.text('3'), findsOneWidget);

    //   // Increment menjadi 4
    //   final addBtn = find.byKey(const Key('btn_add_qty_PROD-1'));
    //   await tester.tap(addBtn);
    //   await tester.pumpAndSettle();
    //   expect(find.text('4'), findsOneWidget);

    //   // Decrement menjadi 3
    //   final minBtn = find.byKey(const Key('btn_min_qty_PROD-1'));
    //   await tester.tap(minBtn);
    //   await tester.pumpAndSettle();
    //   expect(find.text('3'), findsOneWidget);

    //   // Decrement lagi, harus tetap 3 (tidak boleh di bawah MOQ)
    //   await tester.tap(minBtn);
    //   await tester.pumpAndSettle();
    //   expect(find.text('3'), findsOneWidget);
    // });

    testWidgets('8. Menghapus produk dari keranjang secara manual', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);
      
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();

      await clearAllSnackbars(tester);

      await goToCart(tester);
      expect(find.text('Whiskas'), findsOneWidget);

      final deleteBtn = find.byKey(const Key('btn_delete_cart_item_PROD-1'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Keranjang Masih Kosong'), findsOneWidget);
    });

    // testWidgets('9. Mencoba checkout dengan keranjang kosong', (tester) async {
    //   await loginAsRetailer(tester);
    //   await dismissPromoDialog(tester);
    //   await goToCart(tester);

    //   // Proceed to Checkout button should be disabled when empty
    //   final checkoutBtn = find.byKey(const Key('btn_checkout'));
    //   expect(checkoutBtn, findsOneWidget);
    //   final ElevatedButton buttonWidget = tester.widget(checkoutBtn);
    //   expect(buttonWidget.onPressed, isNull);
    // });

    testWidgets('10. Melakukan checkout dengan produk yang ingin dibeli', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);
      
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();

      await clearAllSnackbars(tester);

      await goToCart(tester);

      final checkoutBtn = find.byKey(const Key('btn_checkout'));
      expect(checkoutBtn, findsOneWidget);
      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsWidgets);
      expect(find.text('Buat Pesanan'), findsOneWidget);
    });

    testWidgets('11. Menambahkan produk ke dalam keranjang kemudian user keluar dari aplikasi (force close/logout)', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);
      
      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();
      await clearAllSnackbars(tester);

      // Pergi ke tab profil untuk logout
      await goToProfile(tester);

      // Tap Log Out button
      final logoutBtn = find.text('Keluar');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Konfirmasi Log Out di dialog
      final confirmLogoutBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Keluar'),
      );
      expect(confirmLogoutBtn, findsOneWidget);
      await tester.tap(confirmLogoutBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Login kembali
      await loginAs(tester, 'rt@email.com', '12345678');

      // Buka keranjang dan pastikan produk masih tersimpan
      await goToCart(tester);
      expect(find.text('Whiskas'), findsWidgets);
    });

    // testWidgets('12. Menambahkan produk yang sudah ada didalam keranjang', (tester) async {
    //   await loginAsRetailer(tester);
    //   await goToProductsTab(tester);

    //   await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
    //   await tester.pumpAndSettle();
    //   await clearAllSnackbars(tester);

    //   await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
    //   await tester.pumpAndSettle();
    //   await clearAllSnackbars(tester);

    //   await goToCart(tester);
    //   expect(find.text('2'), findsOneWidget);
    // });

    testWidgets('13. Menambahkan beberapa jenis produk', (tester) async {
      await loginAsRetailer(tester);
      await goToProductsTab(tester);

      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-1')));
      await tester.pumpAndSettle();
      await clearAllSnackbars(tester);

      await tester.tap(find.byKey(const Key('btn_add_to_cart_PROD-2')));
      await tester.pumpAndSettle();
      await clearAllSnackbars(tester);

      await goToCart(tester);
      expect(find.text('Whiskas'), findsWidgets);
      expect(find.text('Pedigree'), findsWidgets);
    });
  });
}
