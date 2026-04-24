import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_stats_helper.dart';

class OrderUserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _duitkuBackendUrl = 'https://backend-payment-kinarya.vercel.app';

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
      throw Exception('Gagal mengambil detail pesanan: $e');
    }
  }

  Future<bool> syncDuitkuPayment(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$_duitkuBackendUrl/check-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (body['statusCode'] == '00') { 
          await OrderStatsHelper.markOrderAsPaid(orderId);
          return true; 
        }
      }
      return false; 
    } catch (e) {
      debugPrint('Error sync payment: $e');
      return false; 
    }
  }
}