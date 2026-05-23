import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'order_stats_helper.dart';
import '../../notification/services/push_notification_service.dart';

class OrderUserController {
  final FirebaseFirestore _firestore;
  final http.Client _client;
  final String _duitkuBackendUrl;
  final PushNotificationService _pushNotificationService;

  OrderUserController({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? backendUrl,
    PushNotificationService? pushNotificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client(),
        _duitkuBackendUrl = backendUrl ?? dotenv.get('BACKEND_URL'),
        _pushNotificationService = pushNotificationService ?? PushNotificationService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception("Error fetching order detail: $e");
    }
  }

  Future<bool> syncDuitkuPayment(String orderId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_duitkuBackendUrl/check-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? duitkuStatus = data['statusCode'] as String?;
        
        if (data['success'] == true && data['status'] == 'Paid') {
          await OrderStatsHelper.markOrderAsPaid(orderId, firestore: _firestore);
          
          await _pushNotificationService.sendNotificationToAdmin(
            title: 'Pembayaran Baru!',
            message: 'Pesanan $orderId telah berhasil dibayar oleh pelanggan.',
            type: 'order',
            relatedId: orderId,
          );
          
          return true;
        } else if (duitkuStatus == '02') {
          await _firestore.collection('orders').doc(orderId).update({
            'status': 'Expired',
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error syncing Duitku: $e");
      return false;
    }
  }
  
  Future<bool> receiveOrder(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data();
      final customerName = orderData?['fullName'] ?? 'Customer';

      await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: 'Delivered', firestore: _firestore);

      await _pushNotificationService.sendNotificationToAdmin(
        title: 'Pesanan Diterima!',
        message: '$customerName telah mengonfirmasi penerimaan pesanan $orderId.',
        type: 'order',
        relatedId: orderId,
      );

      return true;
    } catch (e) {
      debugPrint("Error updating order status: $e");
      return false;
    }
  }

  Future<bool> requestCancellation(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'cancellationReason': reason,
        'cancellationStatus': 'Requested',
      });

      await _pushNotificationService.sendNotificationToAdmin(
        title: 'Pengajuan Pembatalan',
        message: 'Pesanan $orderId diajukan pembatalan oleh retailer.',
        type: 'order',
        relatedId: orderId,
      );

      return true;
    } catch (e) {
      debugPrint("Error requesting cancellation: $e");
      return false;
    }
  }

  Future<void> syncAllPendingOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['Ordered', 'Pending Payment'])
          .get();

      if (snapshot.docs.isEmpty) return;

      debugPrint("Checking ${snapshot.docs.length} pending orders for sync...");

      for (var doc in snapshot.docs) {
        final orderId = doc.id;
        final data = doc.data();
        
        final expiredAt = data['paymentExpiredAt'] as Timestamp?;
        if (expiredAt != null && DateTime.now().isAfter(expiredAt.toDate())) {
          await _firestore.collection('orders').doc(orderId).update({
            'status': 'Expired',
          });
          debugPrint("Order $orderId marked as Expired locally.");
          continue;
        }

        await syncDuitkuPayment(orderId);
      }
    } catch (e) {
      debugPrint("Error syncAllPendingOrders: $e");
    }
  }
}