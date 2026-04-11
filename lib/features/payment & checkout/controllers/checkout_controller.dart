import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CheckoutController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> processCheckout({
    required String fullName,
    required String shippingAddress,
    required String paymentMethod,
    required String paymentMethodCode,
    required String promoCode,
    required double subtotal,
    required double shippingCost,
    required double tax,
    required double total,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0.0,
  }) async {
    try {
      final user = _auth.currentUser;
      final uid = user?.uid ?? 'guest_user';
      final email = user?.email ?? 'customer@kinarya.com';
      final String customerName = user?.displayName ?? email.split('@').first;

      for (var item in items) {
        String? productId = item['productId']?.toString() ?? item['id']?.toString();
        int quantityBought = (item['quantity'] as num?)?.toInt() ?? 1;
        String productName = item['title']?.toString() ?? 'Produk';

        if (productId != null && productId.isNotEmpty) {
          DocumentSnapshot productDoc = await _firestore.collection('products').doc(productId).get();

          if (!productDoc.exists) {
            return {'error': 'Gagal: Produk "$productName" sudah tidak ada di katalog.'};
          }

          int currentStock = (productDoc.data() as Map<String, dynamic>)['stock'] ?? 0;

          if (currentStock < quantityBought) {
            return {
              'error': 'Gagal: Stok "$productName" tidak mencukupi. Anda memesan $quantityBought, tapi stok tersisa $currentStock.'
            };
          }
        }
      }
      
      final String orderId = 'KNY-${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': uid,
        'fullName': fullName,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'promoCode': promoCode,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'shippingCost': shippingCost,
        'tax': tax,
        'total': total,
        'items': items,
        'status': 'Ordered', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      WriteBatch batch = _firestore.batch();

      for (var item in items) {
        String? productId = item['productId']?.toString() ?? item['id']?.toString();
        int quantityBought = (item['quantity'] as num?)?.toInt() ?? 1;

        if (productId != null && productId.isNotEmpty) {
          DocumentReference productRef = _firestore.collection('products').doc(productId);
          
          batch.update(productRef, {
            'stock': FieldValue.increment(-quantityBought)
          });
        }
      }

      await batch.commit();

      const String apiUrl = 'https://backend-payment-kinarya.vercel.app/create-transaction';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'amount': total.toInt(),
          'customerEmail': email,
          'customerName': customerName,
          'paymentMethod': paymentMethodCode,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final String paymentUrl = responseData['paymentUrl'];
          
          await _firestore.collection('orders').doc(orderId).update({
            'paymentUrl': paymentUrl,
          });
          return {'paymentUrl': paymentUrl, 'orderId': orderId};
          
        } else {
          return {'error': 'Duitku ditolak: ${responseData['message']}'};
        }
      } else {
        final errorMsg = (jsonDecode(response.body) as Map)['error'] ?? 'Terjadi kesalahan backend';
        return {'error': 'Server Error (${response.statusCode}): $errorMsg'};
      }

    } catch (e) {
      debugPrint('Checkout Error: $e');
      return {'error': 'Koneksi Error: Tidak dapat terhubung ke server.'};
    }
  }
}