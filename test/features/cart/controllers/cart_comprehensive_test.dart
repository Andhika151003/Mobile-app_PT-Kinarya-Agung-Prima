import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late CartController cartController;
  late MockFirebaseAuth mockAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockFirebaseAuth();
    CartController.setAuthInstance(mockAuth);
    cartController = CartController();
    cartController.clearCart();
  });

  group('Unit Test: Modul Keranjang Belanja (Cart) - TC-83 s/d TC-95', () {
    test(
      'TC-83: Ritel menambahkan produk ke dalam keranjang untuk pertama kali',
      () {
        cartController.addToCart(
          id: 'p1',
          title: 'Produk Test 1',
          variant: 'Botol',
          price: 50000,
          imageUrl: 'url1',
          minOrder: 5,
          stockLimit: 100,
          quantity: 5, // Sesuai MOQ
          category: 'Kesehatan',
        );

        expect(cartController.items.length, 1);
        expect(cartController.items[0].id, 'p1');
        expect(cartController.items[0].quantity, 5);
        expect(cartController.subtotal, 250000);
      },
    );

    test(
      'TC-84: Ritel menambahkan produk saat stok produk dibawah MOQ (gagal masuk keranjang)',
      () {
        // Skenario: MOQ 10, tapi stok cuma 5.
        cartController.addToCart(
          id: 'p2',
          title: 'Produk Stok Tipis',
          variant: 'Box',
          price: 10000,
          imageUrl: 'url2',
          minOrder: 10,
          stockLimit: 5,
          quantity: 10, // User minta 10 (sesuai MOQ)
          category: 'Kesehatan',
        );

        // Harus gagal masuk ke keranjang karena stok di bawah MOQ
        expect(cartController.items.isEmpty, isTrue);
      },
    );

    test(
      'TC-85: Validasi field kuantitas tidak dapat diinput manual (hanya lewat tombol + dan -)',
      () {
        cartController.addToCart(
          id: 'p3',
          title: 'P3',
          variant: 'V',
          price: 10,
          imageUrl: 'i',
          minOrder: 1,
          stockLimit: 10,
          quantity: 1,
          category: 'C',
        );

        // Jika kita ingin menambah, kita panggil increment (kolom bersifat read-only di UI)
        cartController.incrementQty('p3');
        expect(cartController.items[0].quantity, 2);
      },
    );

    test('TC-86: Menambah jumlah produk dengan tombol (+)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'C',
      );

      cartController.incrementQty('p1');
      expect(cartController.items[0].quantity, 2);
    });

    test(
      'TC-87: Menambah jumlah produk hingga melebihi sisa stok (tertahan di stockLimit)',
      () {
        cartController.addToCart(
          id: 'p1',
          title: 'P1',
          variant: 'V',
          price: 1000,
          imageUrl: 'i',
          minOrder: 1,
          stockLimit: 3,
          quantity: 2,
          category: 'C',
        );

        cartController.incrementQty('p1'); // Jadi 3 (Maksimal)
        cartController.incrementQty('p1'); // Tetap 3

        expect(cartController.items[0].quantity, 3);
      },
    );

    test('TC-88: Mengurangi jumlah produk dengan tombol (-)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 5,
        category: 'C',
      );

      cartController.decrementQty('p1');
      expect(cartController.items[0].quantity, 4);
    });

    test(
      'TC-89: Mengurangi jumlah produk pada batas bawah MOQ (tertahan di minOrder)',
      () {
        cartController.addToCart(
          id: 'p1',
          title: 'P1',
          variant: 'V',
          price: 1000,
          imageUrl: 'i',
          minOrder: 5,
          stockLimit: 10,
          quantity: 6,
          category: 'C',
        );

        cartController.decrementQty('p1'); // Jadi 5 (Minimal)
        cartController.decrementQty('p1'); // Tetap 5 (Tidak boleh berkurang di bawah MOQ)

        expect(cartController.items[0].quantity, 5);
      },
    );

    test('TC-90: Menghapus produk dari keranjang secara manual', () {
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'C',
      );

      expect(cartController.items.length, 1);
      cartController.removeItem('p1');
      expect(cartController.items.length, 0);
    });

    test('TC-91: Mencoba checkout dengan keranjang kosong', () {
      expect(cartController.items.isEmpty, isTrue);
      expect(cartController.subtotal, 0);
    });

    test('TC-92: Melakukan checkout dengan produk yang ingin dibeli', () {
      cartController.addToCart(
        id: 'checkout-prod',
        title: 'Produk Beli',
        variant: 'Botol',
        price: 50000,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 100,
        quantity: 2,
        category: 'Kesehatan',
      );

      // Verifikasi keranjang berisi item dan total harga dihitung dengan benar sebelum checkout
      expect(cartController.items.isNotEmpty, isTrue);
      expect(cartController.total, equals(100000.0));
    });

    test('TC-93: Menambahkan produk ke dalam keranjang kemudian user keluar dari aplikasi (Persistence)', () async {
      cartController.addToCart(
        id: 'persist',
        title: 'P',
        variant: 'V',
        price: 100,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 2,
        category: 'C',
      );

      // Membuat controller baru untuk mensimulasikan pembukaan aplikasi kembali
      final newController = CartController();

      // Tunggu sebentar karena proses penyimpanan preference berjalan secara async
      await Future.delayed(const Duration(milliseconds: 100));

      // Verifikasi apakah data keranjang sebelumnya dimuat kembali dengan benar
      expect(newController.items.any((item) => item.id == 'persist'), isTrue);
    });

    test('TC-94: Menambahkan produk yang sudah ada didalam keranjang (jumlah terakumulasi)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 2,
        category: 'C',
      );
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 3,
        category: 'C',
      );

      expect(cartController.items.length, 1);
      expect(cartController.items[0].quantity, 5);
    });

    test('TC-95: Menambahkan beberapa jenis produk', () {
      cartController.addToCart(
        id: 'p1',
        title: 'P1',
        variant: 'V',
        price: 1000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'C',
      );
      cartController.addToCart(
        id: 'p2',
        title: 'P2',
        variant: 'V',
        price: 2000,
        imageUrl: 'i',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'C',
      );

      expect(cartController.items.length, 2);
      expect(cartController.subtotal, 3000);
    });
  });
}
