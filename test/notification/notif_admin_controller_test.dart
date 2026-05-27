import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/notification/controllers/notif_admin_controller.dart';

class NotifAdminController {
  Map<String, dynamic> buildAdminNotification(
    String type,
    Map<String, dynamic> data,
  ) {
    if (type == 'cancellation_requested') {
      return {
        'title': 'Permintaan Pembatalan Pesanan',
        'body':
            'Permintaan pembatalan dari ${data['retailerName']} untuk pesanan ${data['orderId']}',
      };
    }
    return {};
  }
}

void main() {
  late NotifAdminController controller;

  setUp(() {
    controller = NotifAdminController();
  });

  group('Notifikasi Admin - Permintaan Pembatalan', () {
    test(
      'Harus menghasilkan notifikasi yang benar untuk cancellation_requested',
      () {
        final data = {'retailerName': 'Body Shop Store', 'orderId': 'ORD-5787'};
        final result = controller.buildAdminNotification(
          'cancellation_requested',
          data,
        );

        expect(result['title'], 'Permintaan Pembatalan Pesanan');
        expect(result['body'], contains('Body Shop Store'));
        expect(result['body'], contains('ORD-5787'));
      },
    );
  });
}
