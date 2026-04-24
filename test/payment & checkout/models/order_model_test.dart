import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/order/models/order.dart';

void main() {
  group('Unit Test Model OrderItemModel', () {
    test('fromMap harus mengurai data dengan benar', () {
      final map = {
        'productId': 'p1',
        'title': 'Produk 1',
        'variant': 'A',
        'quantity': 2,
        'price': 50.0,
        'imageUrl': 'img1'
      };

      final item = OrderItemModel.fromMap(map);

      expect(item.productId, equals('p1'));
      expect(item.title, equals('Produk 1'));
      expect(item.quantity, equals(2));
      expect(item.price, equals(50.0));
    });

    test('toMap harus mengembalikan map yang benar', () {
      final item = OrderItemModel(
        productId: 'p1',
        title: 'Produk 1',
        variant: 'A',
        quantity: 3,
        price: 60.0,
      );

      final map = item.toMap();
      expect(map['productId'], equals('p1'));
      expect(map['quantity'], equals(3));
    });
  });

  group('Unit Test Model OrderModel', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    test('fromMap harus mengurai Firestore Timestamp dengan benar', () {
      final map = {
        'orderId': 'KNY-123',
        'userId': 'u1',
        'fullName': 'Test User',
        'shippingAddress': 'Alamat',
        'paymentMethod': 'Duitku',
        'promoCode': 'NONE',
        'subtotal': 100.0,
        'shippingCost': 10.0,
        'tax': 0.0,
        'total': 110.0,
        'status': 'Ordered',
        'createdAt': timestamp,
        'items': [
          {'productId': 'p1', 'title': 'P1', 'variant': '-', 'quantity': 1, 'price': 100.0}
        ]
      };

      final order = OrderModel.fromMap(map);

      expect(order.orderId, equals('KNY-123'));
      expect(order.createdAt, isNotNull);
      // Bandingkan dengan milidetik untuk menghindari perbedaan mikrodetik saat konversi
      expect(order.createdAt!.millisecondsSinceEpoch, equals(now.toLocal().millisecondsSinceEpoch));
      expect(order.items.length, equals(1));
      expect(order.items[0].productId, equals('p1'));
    });

    test('toMap harus menangani tanggal null dengan benar', () {
      final order = OrderModel(
        orderId: 'KNY-123',
        userId: 'u1',
        fullName: 'User',
        shippingAddress: 'Alamat',
        paymentMethod: 'Metode',
        promoCode: 'NONE',
        subtotal: 100.0,
        shippingCost: 10.0,
        tax: 0.0,
        total: 110.0,
        items: [],
        status: 'Ordered',
        createdAt: now,
      );

      final map = order.toMap();
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['paidAt'], isNull);
      expect(map['shippedAt'], isNull);
    });

    test('copyWith harus memperbarui status dan tanggal', () {
      final order = OrderModel(
        orderId: 'KNY-123',
        userId: 'u1',
        fullName: 'User',
        shippingAddress: 'Alamat',
        paymentMethod: 'Metode',
        promoCode: 'NONE',
        subtotal: 100.0,
        shippingCost: 10.0,
        tax: 0.0,
        total: 110.0,
        items: [],
        status: 'Ordered',
      );

      final paidDate = DateTime.now();
      final updatedOrder = order.copyWith(status: 'Paid', paidAt: paidDate);

      expect(updatedOrder.status, equals('Paid'));
      expect(updatedOrder.paidAt, equals(paidDate));
      expect(updatedOrder.orderId, equals(order.orderId)); // Tidak berubah
    });
  });
}
