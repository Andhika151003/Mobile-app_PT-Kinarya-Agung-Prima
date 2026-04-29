import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderUserController {
  final FirebaseFirestore _firestore;
  final http.Client _client;
  final String _duitkuBackendUrl;

  OrderUserController({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? backendUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client(),
        _duitkuBackendUrl = backendUrl ?? dotenv.get('BACKEND_URL');

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
          await _firestore.collection('orders').doc(orderId).update({
            'status': 'Paid',
            'paidAt': FieldValue.serverTimestamp(),
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
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("Error updating order status: $e");
      return false;
    }
  }
}