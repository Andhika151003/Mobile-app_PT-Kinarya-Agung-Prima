import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderStatsHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> markOrderAsPaid(String orderId, {String? targetStatus}) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    
    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;

      final data = orderDoc.data() as Map<String, dynamic>;
      final currentStatus = data['status']?.toString() ?? '';
      final bool statsRecorded = data['statsRecorded'] ?? false;

      Map<String, dynamic> orderUpdates = {};
      
      if (targetStatus != null) {
        orderUpdates['status'] = targetStatus;
        if (targetStatus == 'Paid') orderUpdates['paidAt'] = FieldValue.serverTimestamp();
        if (targetStatus == 'Shipped') orderUpdates['shippedAt'] = FieldValue.serverTimestamp();
        if (targetStatus == 'Delivered') orderUpdates['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (currentStatus != 'Paid' && currentStatus != 'Shipped' && currentStatus != 'Delivered') {
        orderUpdates['status'] = 'Paid';
        orderUpdates['paidAt'] = FieldValue.serverTimestamp();
      }

      if (!statsRecorded) {
        final itemsData = data['items'] as List<dynamic>? ?? [];
        for (var itemMap in itemsData) {
          final item = OrderItemModel.fromMap(Map<String, dynamic>.from(itemMap));
          final productId = item.productId;
          if (productId == null || productId.isEmpty) continue;

          final quantity = item.quantity;
          final revenue = (item.price * item.quantity).toInt();

          final productRef = _firestore.collection('products').doc(productId);
          transaction.update(productRef, {
            'monthlySales': FieldValue.increment(quantity),
            'revenue': FieldValue.increment(revenue),
          });
        }
        orderUpdates['statsRecorded'] = true;
      }

      if (orderUpdates.isNotEmpty) {
        transaction.update(orderRef, orderUpdates);
      }
    });
  }
}
