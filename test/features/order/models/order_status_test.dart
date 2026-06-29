import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/order/models/order.dart';
import 'package:ecommerce/core/utils/status_helper.dart';

void main() {
  group('Unit Test: Penerjemah Status Pesanan (TC-99)', () {
    test('TC-99: Mengubah status bahasa Inggris ke tampilan bahasa Indonesia dengan benar', () {
      expect('Ordered'.displayStatus, equals('Belum bayar'));
      expect('Pending Payment'.displayStatus, equals('Belum bayar'));
      expect('Paid'.displayStatus, equals('Dikemas'));
      expect('Shipped'.displayStatus, equals('Dikirim'));
      expect('Delivered'.displayStatus, equals('Selesai'));
      expect('Cancelled'.displayStatus, equals('Dibatalkan'));
      expect('Expired'.displayStatus, equals('Kedaluwarsa'));
      expect('StatusAsing'.displayStatus, equals('StatusAsing'));
    });
  });

  group('Unit Test: Logika Status di OrderModel (TC-99)', () {
    OrderModel createOrderWith({
      required String status,
      DateTime? paidAt,
      DateTime? shippedAt,
      DateTime? deliveredAt,
    }) {
      return OrderModel(
        orderId: 'ORD-TEST',
        userId: 'user123',
        fullName: 'Test User',
        shippingAddress: 'Test Address',
        paymentMethod: 'Test Payment',
        promoCode: '',
        subtotal: 1000.0,
        shippingCost: 0.0,
        tax: 0.0,
        discountAmount: 0.0,
        total: 1000.0,
        items: [],
        status: status,
        paidAt: paidAt,
        shippedAt: shippedAt,
        deliveredAt: deliveredAt,
      );
    }

    test('TC-99: Mengecek status dibatalkan atau kedaluwarsa (isCancelledOrExpired)', () {
      expect(createOrderWith(status: 'Cancelled').isCancelledOrExpired, isTrue);
      expect(createOrderWith(status: 'Expired').isCancelledOrExpired, isTrue);
      expect(createOrderWith(status: 'Ordered').isCancelledOrExpired, isFalse);
      expect(createOrderWith(status: 'Paid').isCancelledOrExpired, isFalse);
      expect(createOrderWith(status: 'Shipped').isCancelledOrExpired, isFalse);
      expect(createOrderWith(status: 'Delivered').isCancelledOrExpired, isFalse);
    });

    group('TC-99: Perhitungan index untuk stepper status', () {
      test('TC-99: Mendapatkan index langsung berdasarkan status pesanan saat ini (Ordered, Paid, Shipped, Delivered)', () {
        expect(createOrderWith(status: 'Ordered').stepperIndex, equals(0));
        expect(createOrderWith(status: 'Paid').stepperIndex, equals(1));
        expect(createOrderWith(status: 'Shipped').stepperIndex, equals(2));
        expect(createOrderWith(status: 'Delivered').stepperIndex, equals(3));
      });

      test('TC-99: Mendapatkan index cadangan berdasarkan tanggal proses jika status di luar stepper (misalnya: Dibatalkan)', () {
        // Jika semua tanggal kosong, default ke index 0
        expect(createOrderWith(status: 'Cancelled').stepperIndex, equals(0));

        // Jika sudah dibayar (paidAt terisi), index naik ke 1
        expect(
          createOrderWith(status: 'Cancelled', paidAt: DateTime.now()).stepperIndex,
          equals(1),
        );

        // Jika sudah dikirim (shippedAt terisi), index naik ke 2
        expect(
          createOrderWith(status: 'Cancelled', shippedAt: DateTime.now()).stepperIndex,
          equals(2),
        );

        // Jika sudah diterima (deliveredAt terisi), index naik ke 3
        expect(
          createOrderWith(status: 'Cancelled', deliveredAt: DateTime.now()).stepperIndex,
          equals(3),
        );
        
        // Jika ada beberapa tanggal, pilih tahap yang paling terakhir (diterima > dikirim > dibayar)
        expect(
          createOrderWith(
            status: 'Cancelled',
            paidAt: DateTime.now(),
            shippedAt: DateTime.now(),
          ).stepperIndex,
          equals(2),
        );
      });
    });
  });
}
