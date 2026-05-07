import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'order_stats_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../notification/services/push_notification_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/auth_repository.dart';

class OrderUserController {
  final OrderRepository _orderRepository;
  final AuthRepository _authRepository;
  final http.Client _client;
  final String _duitkuBackendUrl;
  final PushNotificationService _pushNotificationService;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  OrderUserController({
    OrderRepository? orderRepository,
    AuthRepository? authRepository,
    http.Client? client,
    String? backendUrl,
    PushNotificationService? pushNotificationService,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _authRepository = authRepository ?? AuthRepository(),
        _client = client ?? http.Client(),
        _duitkuBackendUrl = backendUrl ?? dotenv.get('BACKEND_URL'),
        _pushNotificationService = pushNotificationService ?? PushNotificationService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserOrdersStream(String userId) {
    return _orderRepository.getOrdersStreamByUserId(userId);
  }

  Stream<Map<String, dynamic>?> streamOrderById(String orderId) {
    return _orderRepository.streamOrderById(orderId).map((order) => order?.toMap());
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final order = await _orderRepository.getOrderById(orderId);
      return order?.toMap();
    } catch (e) {
      throw Exception("Error fetching order detail: $e");
    }
  }

  Future<String?> syncDuitkuPayment(String orderId) async {
    try {
      final user = _authRepository.currentUser;
      final String? idToken = await user?.getIdToken();

      final response = await _client.post(
        Uri.parse('$_duitkuBackendUrl/check-status'),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'orderId': orderId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final duitkuStatus = data['statusCode'] as String?;
        final statusDesc = data['status'] as String?;
        
        if (duitkuStatus == '00' || statusDesc == 'Paid') {
          await OrderStatsHelper.markOrderAsPaid(orderId);
          
          await _pushNotificationService.sendNotificationToAdmin(
            title: 'Pembayaran Baru!',
            message: 'Pesanan $orderId telah berhasil dibayar oleh pelanggan.',
            type: 'order',
            relatedId: orderId,
          );
          
          // Track Event: Purchase Success
          await _analytics.logPurchase(
            transactionId: orderId,
            currency: 'IDR',
            value: 0, 
          );
          
          return 'Paid';
        } else if (duitkuStatus == '02' || statusDesc == 'Expired') {
           await _orderRepository.updateOrderStatus(orderId, {'status': 'Expired'});
           
           // Track Event: Payment Expired
           await _analytics.logEvent(name: 'payment_expired', parameters: {'order_id': orderId});
           
           return 'Expired';
        } else if (duitkuStatus != null) {
           return duitkuStatus;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error syncing Duitku: $e");
      return null;
    }
  }
  
  Future<bool> receiveOrder(String orderId) async {
    try {
      final orderData = await _orderRepository.getOrderById(orderId);
      final customerName = orderData?.fullName ?? 'Customer';

      await OrderStatsHelper.markOrderAsPaid(orderId, targetStatus: 'Delivered');

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