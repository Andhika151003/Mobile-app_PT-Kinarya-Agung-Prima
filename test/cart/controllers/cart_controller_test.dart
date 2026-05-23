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

  group('Unit Test CartController', () {
    test('Keranjang awal harus kosong', () {
      expect(cartController.items, isEmpty);
      expect(cartController.subtotal, equals(0.0));
    });

    test('Tambah item ke keranjang', () {
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

    test('Menambah item yang sudah ada akan memperbarui jumlahnya', () {
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

    test('Menambah item yang sudah ada tetap menghormati batas stok', () {
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

    test('Menambah jumlah (increment) quantity', () {
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

    test('Mengurangi jumlah (decrement) menghormati minimal order', () {
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

    test('Menghapus item dari keranjang', () {
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

    test('Kalkulasi total harus sesuai subtotal (ongkir 0)', () {
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
