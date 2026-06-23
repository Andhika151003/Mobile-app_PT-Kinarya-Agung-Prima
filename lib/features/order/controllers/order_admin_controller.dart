import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/firebase_provider.dart';
import '../../notification/services/push_notification_service.dart';
import 'order_stats_helper.dart';
import 'order_user_controller.dart';

class OrderAdminController {
  final FirebaseFirestore _firestore;
  final PushNotificationService _pushNotificationService;
  final OrderUserController _userController;

  OrderAdminController({
    FirebaseFirestore? firestore,
    PushNotificationService? pushNotificationService,
    http.Client? client,
    String? backendUrl,
  }) : _firestore = firestore ?? AppFirebase.firestore,
       _pushNotificationService = pushNotificationService ?? PushNotificationService(),
       _userController = OrderUserController(
         firestore: firestore ?? AppFirebase.firestore,
         pushNotificationService: pushNotificationService,
         client: client,
         backendUrl: backendUrl,
       );

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
      debugPrint('[OrderAdminCtrl] getAllOrdersAdmin ERROR: $e');
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
        await OrderStatsHelper.markOrderAsPaid(orderId, firestore: _firestore);
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
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['userId']?.toString() ?? '';

      if (newStatus == 'Paid' || newStatus == 'Shipped' || newStatus == 'Delivered') {
        await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: newStatus, firestore: _firestore);
      } else {
        final updateData = <String, dynamic>{'status': newStatus};
        await _firestore.collection('orders').doc(orderId).update(updateData);
      }

      if (userId.isNotEmpty && userId != 'guest_user') {
        String title = 'Update Pesanan';
        String message = 'Status pesanan $orderId Anda berubah menjadi $newStatus.';

        if (newStatus == 'Paid') {
          title = 'Pembayaran Diterima';
          message = 'Pembayaran untuk pesanan $orderId telah kami konfirmasi.';
        } else if (newStatus == 'Shipped') {
          title = 'Pesanan Sedang Dikirim';
          message = 'Pesanan $orderId Anda telah diserahkan ke kurir.';
        } else if (newStatus == 'Delivered') {
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
    } catch (e) {
      throw Exception('Gagal memperbarui status: $e');
    }
  }

  Future<void> cancelOrder(String orderId, {String? cancellationStatus}) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    
    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) throw Exception('Pesanan tidak ditemukan');

      final data = orderDoc.data() as Map<String, dynamic>;
      final String currentStatus = data['status']?.toString() ?? '';
      final bool statsRecorded = data['statsRecorded'] ?? false;
      final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];

      if (currentStatus == 'Cancelled') throw Exception('Pesanan sudah dibatalkan sebelumnya');

      transaction.update(orderRef, {
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        if (cancellationStatus != null) 'cancellationStatus': cancellationStatus,
      });

      final userId = data['userId']?.toString() ?? '';
      if (userId.isNotEmpty && userId != 'guest_user') {
        _pushNotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Pesanan Dibatalkan',
          message: 'Mohon maaf, pesanan $orderId Anda telah dibatalkan oleh admin.',
          type: 'order',
          relatedId: orderId,
        );
      }

      for (var itemMap in itemsData) {
        final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
        final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;

        if (productId != null && productId.isNotEmpty && quantity > 0) {
          final productRef = _firestore.collection('products').doc(productId);
          
          if (statsRecorded) {
            final int price = (itemMap['price'] as num?)?.toInt() ?? 0;
            final int revenue = price * quantity;
            
            transaction.update(productRef, {
              'stock': FieldValue.increment(quantity),
              'monthlySales': FieldValue.increment(-quantity),
              'revenue': FieldValue.increment(-revenue),
            });
          }
        }
      }
    });
  }

  Future<void> rejectCancellation(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Pesanan tidak ditemukan');
      
      await _firestore.collection('orders').doc(orderId).update({
        'cancellationStatus': 'Rejected',
      });

      final data = orderDoc.data() as Map<String, dynamic>;
      final userId = data['userId']?.toString() ?? '';
      
      if (userId.isNotEmpty && userId != 'guest_user') {
        _pushNotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Pengajuan Pembatalan Ditolak',
          message: 'Admin telah menolak pengajuan pembatalan untuk pesanan $orderId.',
          type: 'order',
          relatedId: orderId,
        );
      }
    } catch (e) {
      throw Exception('Gagal menolak pembatalan: $e');
    }
  }

  List<Map<String, dynamic>> filterAndSearchOrders(
    List<Map<String, dynamic>> allOrders,
    String selectedFilter,
    String searchQuery,
  ) {
    final now = DateTime.now();
    List<Map<String, dynamic>> results = List.from(allOrders);

    if (selectedFilter == 'Today') {
      results = results.where((order) {
        final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) return false;
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      }).toList();
    } else if (selectedFilter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      results = results.where((order) {
        final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) return false;
        return createdAt.isAfter(weekAgo);
      }).toList();
    } else if (['Ordered', 'Paid', 'Shipped', 'Delivered', 'Cancelled', 'Expired'].contains(selectedFilter)) {
      results = results.where((order) => order['status'] == selectedFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((order) {
        final orderId = (order['orderId'] ?? '').toString().toLowerCase();
        final fullName = (order['fullName'] ?? '').toString().toLowerCase();
        final address = (order['shippingAddress'] ?? '').toString().toLowerCase();
        final items = (order['items'] as List<dynamic>? ?? []);
        
        final matchesId = orderId.contains(q);
        final matchesName = fullName.contains(q);
        final matchesAddress = address.contains(q);
        final matchesItems = items.any((item) => 
          (item['title'] ?? '').toString().toLowerCase().contains(q));
          
        return matchesId || matchesName || matchesAddress || matchesItems;
      }).toList();
    }

    return results;
  }

  Future<void> syncAllPendingOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['Ordered', 'Pending Payment'])
          .get();

      if (snapshot.docs.isEmpty) return;

      debugPrint("Admin: Checking ${snapshot.docs.length} pending orders for sync...");

      for (var doc in snapshot.docs) {
        final orderId = doc.id;
        final data = doc.data();

        final expiredAt = data['paymentExpiredAt'] as Timestamp?;
        if (expiredAt != null && DateTime.now().isAfter(expiredAt.toDate())) {
          await _firestore.collection('orders').doc(orderId).update({
            'status': 'Expired',
          });
          debugPrint("Admin: Order $orderId marked as Expired locally.");
          continue;
        }

        await _userController.syncDuitkuPayment(orderId);
      }
    } catch (e) {
      debugPrint("Admin Error syncAllPendingOrders: $e");
    }
  }
}