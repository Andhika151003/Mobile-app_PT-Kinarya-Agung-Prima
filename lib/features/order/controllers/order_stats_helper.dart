import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatsHelper {
  static Future<void> markOrderAsPaid(String orderId,
      {String? targetStatus, FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final orderRef = db.collection('orders').doc(orderId);

    await db.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;

      final data = orderDoc.data() as Map<String, dynamic>;
      final itemsData = data['items'] as List<dynamic>? ?? [];

      // 1. Determine Status & Timestamps
      final updates = _calculateStatusUpdates(data, targetStatus);

      // 2. Process Stats if needed
      final bool statsRecorded = data['statsRecorded'] ?? false;
      if (!statsRecorded) {
        await _recordProductStats(transaction, db, itemsData);
        updates['statsRecorded'] = true;
      }

      // 3. Apply Updates
      if (updates.isNotEmpty) {
        transaction.update(orderRef, updates);
      }
    });
  }

  static Map<String, dynamic> _calculateStatusUpdates(
      Map<String, dynamic> data, String? targetStatus) {
    final currentStatus = data['status']?.toString() ?? '';
    Map<String, dynamic> updates = {};

    if (targetStatus != null) {
      updates['status'] = targetStatus;
      _addTimestamp(updates, targetStatus);
    } else if (_isEligibleForAutoPaid(currentStatus)) {
      updates['status'] = 'Paid';
      updates['paidAt'] = FieldValue.serverTimestamp();
    }
    return updates;
  }

  static bool _isEligibleForAutoPaid(String status) {
    const finalStatuses = ['Paid', 'Shipped', 'Delivered', 'Cancelled', 'Expired'];
    return !finalStatuses.contains(status);
  }

  static void _addTimestamp(Map<String, dynamic> updates, String status) {
    if (status == 'Paid') updates['paidAt'] = FieldValue.serverTimestamp();
    if (status == 'Shipped') updates['shippedAt'] = FieldValue.serverTimestamp();
    if (status == 'Delivered') updates['deliveredAt'] = FieldValue.serverTimestamp();
  }

  static Future<void> _recordProductStats(Transaction transaction,
      FirebaseFirestore db, List<dynamic> itemsData) async {
    for (var itemMap in itemsData) {
      final productId = _extractProductId(itemMap);
      if (productId == null) continue;

      final pRef = db.collection('products').doc(productId);
      final pDoc = await transaction.get(pRef);

      if (pDoc.exists) {
        final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        final double price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
        
        if (quantity > 0) {
          transaction.update(pRef, {
            'monthlySales': FieldValue.increment(quantity),
            'revenue': FieldValue.increment((price * quantity).toInt()),
            'stock': FieldValue.increment(-quantity),
          });
        }
      }
    }
  }

  static String? _extractProductId(dynamic itemMap) {
    return itemMap['productId']?.toString() ?? itemMap['id']?.toString();
  }
}
