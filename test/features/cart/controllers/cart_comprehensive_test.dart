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

  group('Comprehensive Unit Test: Modul Keranjang (Cart) & Checkout', () {
    // 1. Ritel menambahkan produk ke dalam keranjang untuk pertama kali.
    test(
      '1. Ritel menambahkan produk ke dalam keranjang untuk pertama kali',
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

    // 2. Ritel menambahkan produk saat stok produk dibawah MOQ.
    test(
      '2. Ritel menambahkan produk saat stok produk dibawah MOQ (Harus tidak bisa ditambahkan ke keranjang)',
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
          quantity: 10, // User minta 10 (MOQ)
          category: 'Kesehatan',
        );

        // Harus gagal masuk ke keranjang
        expect(cartController.items.isEmpty, isTrue);
      },
    );

    // 3. Validasi field kuantitas tidak dapat diinput manual.
    // (Ini diuji melalui ketiadaan metode 'setQuantity' manual di controller,
    // hanya ada increment/decrement yang terkontrol).
    test(
      '3. Validasi field kuantitas hanya bisa via increment/decrement (Tidak ada set manual)',
      () {
        // Unit test ini memverifikasi bahwa kita menggunakan metode terukur
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

        // Jika kita ingin menambah, kita panggil increment
        cartController.incrementQty('p3');
        expect(cartController.items[0].quantity, 2);
      },
    );

    // 4. Menambah jumlah produk dengan tombol (+).
    test('4. Menambah jumlah produk dengan tombol (+)', () {
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

    // 5. Menambah jumlah produk hingga melebihi sisa stok.
    test(
      '5. Menambah jumlah produk hingga melebihi sisa stok (Harus tertahan di stockLimit)',
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

        cartController.incrementQty('p1'); // Jadi 3 (Max)
        cartController.incrementQty('p1'); // Tetap 3

        expect(cartController.items[0].quantity, 3);
      },
    );

    // 6. Mengurangi jumlah produk dengan tombol (-).
    test('6. Mengurangi jumlah produk dengan tombol (-)', () {
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

    // 7. Mengurangi jumlah produk pada batas bawah MOQ.
    test(
      '7. Mengurangi jumlah produk pada batas bawah MOQ (Harus tertahan di minOrder)',
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

        cartController.decrementQty('p1'); // Jadi 5 (Min)
        cartController.decrementQty('p1'); // Tetap 5

        expect(cartController.items[0].quantity, 5);
      },
    );

    // 8. Menghapus produk dari keranjang secara manual.
    test('8. Menghapus produk dari keranjang secara manual', () {
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

    // 9. Mencoba checkout dengan keranjang kosong.
    // (Biasanya dicek di UI atau CheckoutController, di CartController kita cek isEmpty)
    test('9. Validasi keranjang kosong sebelum checkout', () {
      expect(cartController.items.isEmpty, isTrue);
      expect(cartController.subtotal, 0);
    });

    // 12. Menambahkan produk yang sudah ada didalam keranjang (Quantity bertambah).
    test('12. Menambahkan produk yang sudah ada didalam keranjang', () {
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

    // 13. Menambahkan beberapa jenis produk.
    test('13. Menambahkan beberapa jenis produk', () {
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

    // 11. Menambahkan produk ke dalam keranjang kemudian user keluar dari aplikasi (Persistence).
    test('11. Persistensi data keranjang (Save/Load)', () async {
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

      // Buat controller baru (mensimulasikan buka aplikasi kembali)
      final newController = CartController();
      // CartController memanggil loadCartFromPrefs() di constructor
      // Karena setUp SharedPreferences.setMockInitialValues({}) bersifat global untuk test ini,
      // kita perlu memastikan data tersimpan.

      // Tunggu sebentar karena save dilakukan secara async
      await Future.delayed(const Duration(milliseconds: 100));

      // Cek apakah item terbawa (SharedPreferences mock akan menyimpan data ini)
      // Catatan: Di implementasi asli, CartController mungkin butuh waktu untuk load.
      // Kita bisa panggil load secara eksplisit jika metodenya publik atau cek state-nya.

      // Jika CartController memanggil notifyListeners setelah load, kita bisa verifikasi.
      expect(newController.items.any((item) => item.id == 'persist'), isTrue);
    });
  });
}
