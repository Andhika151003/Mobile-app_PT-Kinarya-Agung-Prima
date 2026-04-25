import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/cart/models/cart.dart';

void main() {
  group('Unit Test Model CartItem', () {
    test('toMap harus mengembalikan map yang benar', () {
      final item = CartItem(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        quantity: 2,
        minOrder: 1,
        stockLimit: 10,
      );

      final map = item.toMap();

      expect(map['id'], equals('p1'));
      expect(map['title'], equals('Produk 1'));
      expect(map['price'], equals(100.0));
      expect(map['quantity'], equals(2));
      expect(map['minOrder'], equals(1));
      expect(map['stockLimit'], equals(10));
    });

    test('Jumlah (quantity) default harus 1', () {
      final item = CartItem(
        id: 'p1',
        title: 'Produk 1',
        variant: 'Standar',
        price: 100.0,
        imageUrl: 'url1',
        minOrder: 1,
        stockLimit: 10,
      );

      expect(item.quantity, equals(1));
    });
  });
}
