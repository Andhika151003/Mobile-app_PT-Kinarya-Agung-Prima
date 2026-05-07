import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/error/failures.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/utils/result.dart';
import '../../notification/services/push_notification_service.dart';
import '../controllers/order_stats_helper.dart';

class OrderService {
  final OrderRepository _orderRepository;
  final PushNotificationService _pushNotificationService;

  OrderService({
    OrderRepository? orderRepository,
    PushNotificationService? pushNotificationService,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _pushNotificationService =
            pushNotificationService ?? PushNotificationService();

  Future<Result<void>> updateStatusWithNotification({
    required String orderId,
    required String newStatus,
    required String userId,
  }) async {
    try {
      if (newStatus == 'Paid' || newStatus == 'Shipped' || newStatus == 'Delivered') {
        await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: newStatus);
      } else {
        await _orderRepository.updateOrderStatus(orderId, {'status': newStatus});
      }

      if (userId.isNotEmpty && userId != 'guest_user') {
        await _sendNotification(userId, orderId, newStatus);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal update status: $e'));
    }
  }

  Future<void> _sendNotification(String userId, String orderId, String status) async {
    String title = 'Update Pesanan';
    String message = 'Status pesanan $orderId Anda berubah menjadi $status.';

    if (status == 'Paid') {
      title = 'Pembayaran Diterima';
      message = 'Pembayaran untuk pesanan $orderId telah kami konfirmasi.';
    } else if (status == 'Shipped') {
      title = 'Pesanan Sedang Dikirim';
      message = 'Pesanan $orderId Anda telah diserahkan ke kurir.';
    } else if (status == 'Delivered') {
      title = 'Pesanan Telah Tiba';
      message = 'Pesanan $orderId Anda telah sampai di tujuan.';
    }

    await _pushNotificationService.sendNotificationToUser(
      userId: userId,
      title: title,
      message: message,
      type: 'order',
      relatedId: orderId,
    );
  }

  Future<Result<void>> cancelOrderWithNotification({
    required String orderId,
    required String userId,
  }) async {
    try {
      await _orderRepository.updateOrderStatus(orderId, {
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (userId.isNotEmpty && userId != 'guest_user') {
        await _pushNotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Pesanan Dibatalkan',
          message: 'Mohon maaf, pesanan $orderId Anda telah dibatalkan.',
          type: 'order',
          relatedId: orderId,
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal membatalkan pesanan: $e'));
    }
  }
}
