import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatsHelper {
  static Future<void> markOrderAsPaid(String orderId, {String? targetStatus, FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final orderRef = db.collection('orders').doc(orderId);
    
    await db.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;

      final data = orderDoc.data() as Map<String, dynamic>;
      final itemsData = data['items'] as List<dynamic>? ?? [];
      
      Map<String, DocumentSnapshot> productDocs = {};
      for (var itemMap in itemsData) {
        final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
        if (productId != null && productId.isNotEmpty && !productDocs.containsKey(productId)) {
          final pRef = db.collection('products').doc(productId);
          productDocs[productId] = await transaction.get(pRef);
        }
      }

      final currentStatus = data['status']?.toString() ?? '';
      final bool statsRecorded = data['statsRecorded'] ?? false;

      Map<String, dynamic> orderUpdates = {};
      
      if (targetStatus != null) {
        orderUpdates['status'] = targetStatus;
        if (targetStatus == 'Paid') orderUpdates['paidAt'] = FieldValue.serverTimestamp();
        if (targetStatus == 'Shipped') orderUpdates['shippedAt'] = FieldValue.serverTimestamp();
        if (targetStatus == 'Delivered') orderUpdates['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (currentStatus != 'Paid' && currentStatus != 'Shipped' && currentStatus != 'Delivered' && currentStatus != 'Cancelled' && currentStatus != 'Expired') {
        orderUpdates['status'] = 'Paid';
        orderUpdates['paidAt'] = FieldValue.serverTimestamp();
      }

      if (!statsRecorded) {
        for (var itemMap in itemsData) {
          final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
          if (productId == null || productId.isEmpty) continue;

          final pDoc = productDocs[productId];
          if (pDoc != null && pDoc.exists) {
            final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
            final double price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
            final int revenue = (price * quantity).toInt();

            if (quantity > 0) {
              transaction.update(pDoc.reference, {
                'monthlySales': FieldValue.increment(quantity),
                'revenue': FieldValue.increment(revenue),
                'stock': FieldValue.increment(-quantity),
              });
            }
          }
        }
        orderUpdates['statsRecorded'] = true;
      }

      if (orderUpdates.isNotEmpty) {
        transaction.update(orderRef, orderUpdates);
      }
    });
  }
}
