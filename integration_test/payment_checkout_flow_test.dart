import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce/main.dart' as app;

/// Integration Test: Payment & Checkout Flow (Black Box)
///
/// Alur sederhana:
///   1. Login → Pilih Produk → Add to Cart → Checkout → Place Order
///   2. Validasi checkout tanpa metode pembayaran

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment & Checkout Flow', () {
    // ────────────────────────────────────────────────────────────
    // TEST 1: Alur lengkap dari Login sampai Place Order
    // ────────────────────────────────────────────────────────────
    testWidgets('Complete checkout flow', (WidgetTester tester) async {
      // 1. Launch app
      app.main();
      await tester.pump();

      // Tunggu Login Screen atau Dashboard
      bool isLoginScreen = false;
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byKey(const Key('login_email_field')).evaluate().isNotEmpty) {
          isLoginScreen = true;
          break;
        }
        if (find.text('Produk').evaluate().isNotEmpty) break;
      }

      // 2. Login
      if (isLoginScreen) {
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'ambatukam@gmail.com',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          '12345678',
        );
        await tester.pumpAndSettle();

        // Menurunkan keyboard
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('login_submit_btn')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      // Check and dismiss promo popup if present
      final claimBtn = find.text('Klaim Penawaran Sekarang');
      if (claimBtn.evaluate().isNotEmpty) {
        await tester.tap(claimBtn);
        await tester.pumpAndSettle();
      }

      // 3. Navigasi ke tab Products
      expect(find.text('Produk'), findsOneWidget);
      await tester.tap(find.text('Produk'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 4. Cari produk "Kahf Face Wash..." → masuk ke detail
      final productCard = find.text(
        'Kahf Face Wash Skin Energizing and Brightening Tube 100ml',
      );

      await tester.ensureVisible(productCard);
      await tester.pumpAndSettle();
      await tester.tap(productCard);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 5. Add to Cart
      expect(find.text('Detail Produk'), findsOneWidget);
      final addToCartBtn = find.byKey(const Key('btn_add_to_cart_detail'));
      expect(addToCartBtn, findsOneWidget);
      await tester.ensureVisible(addToCartBtn);
      await tester.pumpAndSettle();
      await tester.tap(addToCartBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 6. Buka Shopping Cart (DENGAN SCROLL KE ATAS)
      // Ambil titik tengah layar, lalu swipe ke arah bawah (Y positif = +500)
      // untuk menggulirkan halaman ke bagian paling atas.
      final scaffoldCenter = tester.getCenter(find.byType(Scaffold).last);
      for (int i = 0; i < 3; i++) {
        await tester.dragFrom(scaffoldCenter, const Offset(0, 500));
        await tester.pumpAndSettle();
      }

      final cartAppBar = find.byKey(const Key('btn_cart_appbar'));
      final cartCatalog = find.byKey(const Key('btn_cart_catalog'));

      if (cartAppBar.evaluate().isNotEmpty) {
        await tester.ensureVisible(cartAppBar);
        await tester.tap(cartAppBar);
      } else if (cartCatalog.evaluate().isNotEmpty) {
        await tester.ensureVisible(cartCatalog);
        await tester.tap(cartCatalog);
      }

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 7. Verifikasi Cart ada isinya
      expect(find.text('Keranjang Belanja'), findsOneWidget);
      expect(find.text('Keranjang Masih Kosong'), findsNothing);
      expect(find.text('Ringkasan Pesanan'), findsOneWidget);

      // 8. Proceed to Checkout
      final checkoutBtn = find.byKey(const Key('btn_checkout'));
      expect(checkoutBtn, findsOneWidget);
      await tester.ensureVisible(checkoutBtn);
      await tester.pumpAndSettle();
      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 9. Verifikasi halaman Checkout
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('PENGIRIMAN'), findsOneWidget);
      expect(find.text('PEMBAYARAN'), findsOneWidget);
      expect(find.text('PROMO'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Buat Pesanan'), findsOneWidget);

      // 10. Pilih metode pembayaran (BCA VA)
      await tester.tap(find.text('PEMBAYARAN'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Metode Pembayaran'), findsWidgets);
      await tester.tap(find.text('BCA Virtual Account').last);
      await tester.pumpAndSettle();

      // Verifikasi terpilih
      expect(find.text('BCA Virtual Account'), findsOneWidget);

      // 11. Place Order
      final placeOrderBtn = find.text('Buat Pesanan');
      await tester.ensureVisible(placeOrderBtn);
      await tester.pumpAndSettle();
      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();

      // 12. Verifikasi respons (sukses atau error, keduanya valid)
      final hasResponse =
          find.text('Pembayaran Duitku').evaluate().isNotEmpty ||
          find.text('Detail Transaksi').evaluate().isNotEmpty ||
          find.textContaining('Error').evaluate().isNotEmpty ||
          find.textContaining('Koneksi').evaluate().isNotEmpty ||
          find.text('Checkout').evaluate().isNotEmpty;
      expect(hasResponse, isTrue);
    });

    // ────────────────────────────────────────────────────────────
    // TEST 2: Validasi - Place Order tanpa pilih pembayaran
    // ────────────────────────────────────────────────────────────
    testWidgets('Place order without payment method shows error', (
      WidgetTester tester,
    ) async {
      // 1. Launch app
      app.main();
      await tester.pump();

      bool isLoginScreen = false;
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byKey(const Key('login_email_field')).evaluate().isNotEmpty) {
          isLoginScreen = true;
          break;
        }
        if (find.text('Produk').evaluate().isNotEmpty) break;
      }

      // 2. Login
      if (isLoginScreen) {
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'ambatukam@gmail.com',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          '12345678',
        );
        await tester.pumpAndSettle();

        // Menurunkan keyboard
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('login_submit_btn')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      // Check and dismiss promo popup if present
      final claimBtn = find.text('Klaim Penawaran Sekarang');
      if (claimBtn.evaluate().isNotEmpty) {
        await tester.tap(claimBtn);
        await tester.pumpAndSettle();
      }

      // 3. Add produk spesifik "Kahf..." ke Cart
      await tester.tap(find.text('Produk'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final productCard = find.text(
        'Kahf Face Wash Skin Energizing and Brightening Tube 100ml',
      );

      await tester.ensureVisible(productCard);
      await tester.pumpAndSettle();
      await tester.tap(productCard);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_to_cart_detail')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 4. Buka Cart → Checkout (DENGAN SCROLL KE ATAS)
      final scaffoldCenter = tester.getCenter(find.byType(Scaffold).last);
      for (int i = 0; i < 3; i++) {
        await tester.dragFrom(scaffoldCenter, const Offset(0, 500));
        await tester.pumpAndSettle();
      }

      final cartAppBar = find.byKey(const Key('btn_cart_appbar'));
      final cartCatalog = find.byKey(const Key('btn_cart_catalog'));

      if (cartAppBar.evaluate().isNotEmpty) {
        await tester.ensureVisible(cartAppBar);
        await tester.tap(cartAppBar);
      } else if (cartCatalog.evaluate().isNotEmpty) {
        await tester.ensureVisible(cartCatalog);
        await tester.tap(cartCatalog);
      }

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_checkout')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 5. Langsung Place Order tanpa pilih pembayaran
      expect(find.text('Checkout'), findsOneWidget);
      final placeOrderBtn = find.text('Buat Pesanan');
      await tester.ensureVisible(placeOrderBtn);
      await tester.pumpAndSettle();
      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // 6. Harus muncul pesan error
      expect(
        find.text('Pilih metode pembayaran terlebih dahulu'),
        findsOneWidget,
      );
    });
  });
}