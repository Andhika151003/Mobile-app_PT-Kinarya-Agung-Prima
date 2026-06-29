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

  group('Unit Test CartController - TC-83 s/d TC-95', () {
    test('TC-91: Keranjang awal harus kosong sebelum checkout', () {
      expect(cartController.items, isEmpty);
      expect(cartController.subtotal, equals(0.0));
    });

    test('TC-83: Ritel menambahkan produk ke dalam keranjang untuk pertama kali', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 2,
        category: 'Test Category',
      );

      expect(cartController.items.length, equals(1));
      expect(cartController.items[0].id, equals('p1'));
      expect(cartController.items[0].quantity, equals(2));
      expect(cartController.subtotal, equals(200.0));
    });

    test('TC-94: Menambahkan produk yang sudah ada didalam keranjang', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 2,
        category: 'Test Category',
      );

      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 3,
        category: 'Test Category',
      );

      expect(cartController.items.length, equals(1));
      expect(cartController.items[0].quantity, equals(5));
    });

    test('TC-87: Menambah jumlah produk hingga melebihi sisa stok (menghormati batas stok)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 5,
        quantity: 3,
        category: 'Test Category',
      );

      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 5,
        quantity: 4,
        category: 'Test Category',
      );

      expect(cartController.items[0].quantity, equals(5));
    });

    test('TC-86: Menambah jumlah produk dengan tombol (+)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'Test Category',
      );

      cartController.incrementQty('p1');
      expect(cartController.items[0].quantity, equals(2));
    });

    test('TC-89: Mengurangi jumlah produk pada batas bawah MOQ (menghormati minimal order)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 2,
        stockLimit: 10,
        quantity: 2,
        category: 'Test Category',
      );

      cartController.decrementQty('p1');
      expect(cartController.items[0].quantity, equals(2));
    });

    test('TC-90: Menghapus produk dari keranjang secara manual', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'Test Category',
      );

      cartController.removeItem('p1');
      expect(cartController.items, isEmpty);
    });

    test('TC-92: Melakukan checkout dengan produk yang ingin dibeli (Kalkulasi total sesuai subtotal)', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
        category: 'Test Category',
      );

      // shippingCost adalah 0.0 di controller saat ini
      expect(cartController.total, equals(100.0 + 0.0));
    });
  });
}
