import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../notification/services/push_notification_service.dart';
import '../../../core/repositories/product_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/auth_repository.dart';

class CheckoutController {
  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;
  final AuthRepository _authRepository;
  final http.Client _client;
  final String _backendUrl;
  final PushNotificationService _pushNotificationService;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  CheckoutController({
    ProductRepository? productRepository,
    OrderRepository? orderRepository,
    AuthRepository? authRepository,
    http.Client? client,
    String? backendUrl,
    PushNotificationService? pushNotificationService,
  }) : _productRepository = productRepository ?? ProductRepository(),
       _orderRepository = orderRepository ?? OrderRepository(),
       _authRepository = authRepository ?? AuthRepository(),
       _client = client ?? http.Client(),
       _backendUrl = backendUrl ?? dotenv.get('BACKEND_URL'),
       _pushNotificationService = pushNotificationService ?? PushNotificationService();

  Future<Map<String, String>> processCheckout({
    required String fullName,
    required String shippingAddress,
    required String? phoneNumber,
    required String paymentMethod,
    required String paymentMethodCode,
    String? promoId,
    required String promoCode,
    required double subtotal,
    required double shippingCost,
    required double tax,
    required double total,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0.0,
  }) async {
    try {
      final user = _authRepository.currentUser;
      final uid = user?.uid ?? 'guest_user';
      final email = user?.email ?? 'customer@kinarya.com';
      final String customerName = user?.displayName ?? email.split('@').first;

      for (var item in items) {
        String? productId =
            item['productId']?.toString() ?? item['id']?.toString();
        int quantityBought = (item['quantity'] as num?)?.toInt() ?? 1;
        String productName = item['title']?.toString() ?? 'Produk';

        if (productId != null && productId.isNotEmpty) {
          final productModel = await _productRepository.getProductById(productId);

          if (productModel == null) {
            return {
              'error':
                  'Gagal: Produk "$productName" sudah tidak ada di katalog.',
            };
          }

          int currentStock = productModel.stock;

          if (currentStock < quantityBought) {
            return {
              'error':
                  'Gagal: Stok "$productName" tidak mencukupi. Anda memesan $quantityBought, tapi stok tersisa $currentStock.',
            };
          }
        }
      }

      final String orderId = 'KNY-${DateTime.now().millisecondsSinceEpoch}';

      final orderData = {
        'orderId': orderId,
        'userId': uid,
        'fullName': fullName,
        'shippingAddress': shippingAddress,
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'promoId': promoId,
        'promoCode': promoCode,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'shippingCost': shippingCost,
        'tax': tax,
        'total': total,
        'items': items,
        'status': 'Ordered',
      };

      await _orderRepository.createOrder(orderData);

      await _pushNotificationService.sendNotificationToAdmin(
        title: 'Pesanan Baru Masuk!',
        message: 'Pesanan $orderId telah dibuat oleh $fullName.',
        type: 'order',
        relatedId: orderId,
      );

      final String apiUrl = '$_backendUrl/create-transaction';
      
      // Track Event: Checkout Started
      await _analytics.logEvent(
        name: 'begin_checkout',
        parameters: {
          'order_id': orderId,
          'value': total,
          'currency': 'IDR',
        },
      );

      // Ambil Firebase ID Token untuk otentikasi di backend (Security)
      final String? idToken = await user?.getIdToken();

      final response = await _client.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'orderId': orderId,
          'amount': total.toInt(),
          'customerEmail': email,
          'customerName': customerName,
          'paymentMethod': paymentMethodCode,
          'expiryPeriod': 60, // Waktu kedaluwarsa dalam menit (60 menit = 1 jam)
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final String paymentUrl = responseData['paymentUrl'];

          await _orderRepository.updateOrderStatus(orderId, {
            'paymentUrl': paymentUrl,
          });

          // Track Event: Payment Info Generated
          await _analytics.logEvent(
            name: 'generate_payment_info',
            parameters: {
              'order_id': orderId,
              'payment_method': paymentMethod,
            },
          );

          return {'paymentUrl': paymentUrl, 'orderId': orderId};
        } else {
          return {'error': 'Duitku ditolak: ${responseData['message']}'};
        }
      } else {
        final errorMsg =
            (jsonDecode(response.body) as Map)['error'] ??
            'Terjadi kesalahan backend';
        return {'error': 'Server Error (${response.statusCode}): $errorMsg'};
      }
    } catch (e) {
      debugPrint('Checkout Error: $e');
      return {'error': 'Koneksi Error: Tidak dapat terhubung ke server.'};
    }
  }
}
