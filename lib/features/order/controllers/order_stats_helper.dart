import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/repositories/order_repository.dart';

class OrderStatsHelper {
  static Future<void> markOrderAsPaid(String orderId,
      {String? targetStatus, FirebaseFirestore? firestore}) async {
    final orderRepository = OrderRepository(firestore: firestore);
    await orderRepository.processOrderPaymentAndStats(orderId, targetStatus: targetStatus);
  }
}
