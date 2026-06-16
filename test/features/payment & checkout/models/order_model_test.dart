import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/order/models/order.dart';

void main() {
  group('Unit Test Model: OrderItemModel', () {
    test(
      'fromMap harus melakukan deserialisasi Map menjadi objek OrderItemModel dengan akurat',
      () {
        // Arrange: Menyiapkan simulasi payload data mentah (JSON/Map) dari Firestore
        final Map<String, dynamic> firestoreMap = {
          'productId': 'p1',
          'title': 'Produk 1',
          'variant': 'A',
          'quantity': 2,
          'price': 50.0,
          'imageUrl': 'img1',
        };

        // Act: Mengeksekusi fungsi konversi data mentah menjadi entitas Model
        final resultItem = OrderItemModel.fromMap(firestoreMap);

        // Assert: Memastikan setiap properti terpetakan dengan sempurna
        expect(resultItem.productId, equals('p1'));
        expect(resultItem.title, equals('Produk 1'));
        expect(resultItem.quantity, equals(2));
        expect(resultItem.price, equals(50.0));
      },
    );

    test(
      'toMap harus melakukan serialisasi objek OrderItemModel menjadi Map yang sesuai skema database',
      () {
        // Arrange: Menyiapkan objek Dart yang valid dan siap dikirim
        final item = OrderItemModel(
          productId: 'p1',
          title: 'Produk 1',
          variant: 'A',
          quantity: 3,
          price: 60.0,
        );

        // Act: Mengeksekusi pembentukan objek menjadi Map
        final resultMap = item.toMap();

        // Assert: Memastikan struktur Map siap ditulis ke database tanpa ada key yang salah eja
        expect(resultMap['productId'], equals('p1'));
        expect(resultMap['quantity'], equals(3));
        expect(resultMap['price'], equals(60.0));
      },
    );
  });

  group('Unit Test Model: OrderModel', () {
    final currentDateTime = DateTime.now();
    final currentTimestamp = Timestamp.fromDate(currentDateTime);

    test(
      'fromMap harus mengurai data kompleks termasuk konversi mutlak Firestore Timestamp ke DateTime',
      () {
        // Arrange: Simulasi satu dokumen utuh dari koleksi 'orders' di Firestore
        final Map<String, dynamic> firestoreDocument = {
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
          'createdAt': currentTimestamp,
          'items': [
            {
              'productId': 'p1',
              'title': 'P1',
              'variant': '-',
              'quantity': 1,
              'price': 100.0,
            },
          ],
        };

        // Act: Mengubah dokumen Firestore menjadi objek Dart
        final resultOrder = OrderModel.fromMap(firestoreDocument);

        // Assert: Memastikan arsitektur data utuh, presisi waktu terjaga, dan nested list (items) terurai
        expect(resultOrder.orderId, equals('KNY-123'));
        expect(resultOrder.createdAt, isNotNull);
        // Validasi berbasis milidetik untuk mencegah kegagalan minor akibat presisi mikrodetik
        expect(
          resultOrder.createdAt!.millisecondsSinceEpoch,
          equals(currentDateTime.toLocal().millisecondsSinceEpoch),
        );
        expect(resultOrder.items.length, equals(1));
        expect(resultOrder.items.first.productId, equals('p1'));
      },
    );

    test(
      'toMap harus menangani serialisasi secara aman pada field tanggal operasional yang bernilai null',
      () {
        // Arrange: Instansiasi objek order baru yang belum memiliki status pembayaran atau pengiriman
        final newOrder = OrderModel(
          orderId: 'KNY-123',
          userId: 'u1',
          fullName: 'User',
          shippingAddress: 'Alamat',
          paymentMethod: 'Metode',
          promoCode: 'NONE',
          subtotal: 100.0,
          shippingCost: 10.0,
          tax: 0.0,
          discountAmount: 0.0,
          total: 110.0,
          items: [],
          status: 'Ordered',
          createdAt: currentDateTime,
        );

        // Act: Konversi format menuju skema penyimpanan Firestore
        final resultMap = newOrder.toMap();

        // Assert: Memvalidasi kebersihan data sebelum proses write dilakukan ke backend
        expect(resultMap['createdAt'], isA<Timestamp>());
        expect(resultMap['paidAt'], isNull);
        expect(resultMap['shippedAt'], isNull);
      },
    );

    test(
      'copyWith harus menghasilkan instance baru dengan pembaruan state tanpa memutasikan data asli (immutable)',
      () {
        // Arrange: Menyiapkan objek order dengan status transaksi awal
        final initialOrder = OrderModel(
          orderId: 'KNY-123',
          userId: 'u1',
          fullName: 'User',
          shippingAddress: 'Alamat',
          paymentMethod: 'Metode',
          promoCode: 'NONE',
          subtotal: 100.0,
          shippingCost: 10.0,
          tax: 0.0,
          discountAmount: 0.0,
          total: 110.0,
          items: [],
          status: 'Ordered',
        );
        final paymentTime = DateTime.now();

        // Act: Memanipulasi state dengan membuat salinan yang diperbarui
        final updatedOrder = initialOrder.copyWith(
          status: 'Paid',
          paidAt: paymentTime,
        );

        // Assert: Mengisolasi perubahan state agar data lain tetap identik
        expect(updatedOrder.status, equals('Paid'));
        expect(updatedOrder.paidAt, equals(paymentTime));
        expect(updatedOrder.orderId, equals(initialOrder.orderId));
      },
    );
  });
}
