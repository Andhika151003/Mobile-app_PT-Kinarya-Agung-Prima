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
        if (data['success'] == true && data['status'] == 'Paid') {
          await OrderStatsHelper.markOrderAsPaid(orderId, firestore: _firestore);
          
          await _pushNotificationService.sendNotificationToAdmin(
            title: 'Pembayaran Baru!',
            message: 'Pesanan $orderId telah berhasil dibayar oleh pelanggan.',
            type: 'order',
            relatedId: orderId,
          );
          
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
}