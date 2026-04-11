import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_stats_helper.dart';

class OrderAdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllOrdersAdmin() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final docs = snapshot.docs.map((d) => d.data()).toList();
      
      docs.sort((a, b) {
        final aTs = a['createdAt'] as Timestamp?;
        final bTs = b['createdAt'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });
      
      return docs;
    } catch (e) {
      throw Exception('Gagal mengambil seluruh data pesanan: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      final String status = data['status']?.toString() ?? '';
      final bool statsRecorded = data['statsRecorded'] ?? false;

      if (!statsRecorded && (status == 'Paid' || status == 'Shipped' || status == 'Delivered')) {
        await OrderStatsHelper.markOrderAsPaid(orderId);
        final updatedDoc = await _firestore.collection('orders').doc(orderId).get();
        return updatedDoc.data();
      }

      return data;
    } catch (e) {
      throw Exception('Gagal mengambil detail pesanan: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (newStatus == 'Paid' || newStatus == 'Shipped' || newStatus == 'Delivered') {
        await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: newStatus);
      } else {
        final updateData = <String, dynamic>{'status': newStatus};
        await _firestore.collection('orders').doc(orderId).update(updateData);
      }
    } catch (e) {
      throw Exception('Gagal memperbarui status: $e');
    }
  }
}