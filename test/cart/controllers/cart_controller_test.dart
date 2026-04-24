import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/cart/controllers/cart_controller.dart';

void main() {
  late CartController cartController;

  setUp(() {
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
      );

      cartController.decrementQty('p1');
      expect(cartController.items[0].quantity, equals(2)); // Tidak boleh kurang dari minOrder
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
      );

      cartController.removeItem('p1');
      expect(cartController.items, isEmpty);
    });

    test('Kalkulasi total harus termasuk ongkir', () {
      cartController.addToCart(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
        quantity: 1,
      );

      // shippingCost adalah 9.99
      expect(cartController.total, equals(100.0 + 9.99));
    });
  });
}
