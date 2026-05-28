import 'package:flutter_test/flutter_test.dart';

class NotifUserController {
  Map<String, String> buildUserNotification(
    String type,
    Map<String, String> data,
  ) {
    switch (type) {
      case 'transaction_approved':
        return {
          'title': 'Pembayaran Diverifikasi',
          'body':
              'Pembayaran untuk transaksi ${data['transactionId']} telah disetujui Admin.',
        };
      case 'delivery_approved':
        return {
          'title': 'Pengiriman Disetujui',
          'body':
              'Pengiriman untuk pesanan ${data['orderId']} sedang dalam proses pengiriman.',
        };
      case 'delivery_rejected':
        return {
          'title': 'Pengiriman Ditolak',
          'body':
              'Pengiriman untuk pesanan ${data['orderId']} ditolak. Alasan: ${data['reason']}',
        };
      case 'cancellation_accepted':
        return {
          'title': 'Pembatalan Disetujui',
          'body': 'Permintaan pembatalan telah disetujui Admin.',
        };
      case 'cancellation_rejected':
        return {
          'title': 'Pembatalan Ditolak',
          'body': 'Pesanan tetap diproses.',
        };
      default:
        return {'title': '', 'body': ''};
    }
  }
}

void main() {
  late NotifUserController controller;

  setUp(() {
    controller = NotifUserController();
  });

  group('TC-04: Approve Transaksi', () {
    test('Notifikasi ke user: pembayaran diverifikasi', () {
      final data = {'transactionId': 'TRX25040001'};
      final result = controller.buildUserNotification(
        'transaction_approved',
        data,
      );

      expect(result['title'], 'Pembayaran Diverifikasi');
      expect(result['body'], contains('TRX25040001'));
      expect(result['body'], contains('disetujui Admin'));
    });
  });

  group('TC-06: Approve Delivery', () {
    test('Notifikasi pengiriman disetujui', () {
      final data = {'orderId': 'ORD-5785'};
      final result = controller.buildUserNotification(
        'delivery_approved',
        data,
      );

      expect(result['title'], 'Pengiriman Disetujui');
      expect(result['body'], contains('ORD-5785'));
      expect(
        result['body'],
        contains('sedang dalam proses pengiriman'),
      );
    });
  });

  group('TC-07: Reject Delivery', () {
    test('Notifikasi penolakan dengan alasan', () {
      final data = {'orderId': 'ORD-5786', 'reason': 'Stok tidak tersedia'};
      final result = controller.buildUserNotification(
        'delivery_rejected',
        data,
      );

      expect(result['title'], 'Pengiriman Ditolak');
      expect(result['body'], contains('ORD-5786'));
      expect(result['body'], contains('Stok tidak tersedia'));
    });
  });

  group('Accept & Reject Cancellation', () {
    test('Accept cancellation', () {
      final data = {'orderId': 'ORD-5787'};
      final result = controller.buildUserNotification(
        'cancellation_accepted',
        data,
      );

      expect(result['title'], 'Pembatalan Disetujui');
      expect(result['body'], contains('telah disetujui Admin'));
    });

    test('Reject cancellation', () {
      final data = {'orderId': 'ORD-5789'};
      final result = controller.buildUserNotification(
        'cancellation_rejected',
        data,
      );

      expect(result['title'], 'Pembatalan Ditolak');
      expect(result['body'], contains('Pesanan tetap diproses'));
    });
  });
}
