import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../supabase_storage_service.dart';

class AdminProfileController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminProfileController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          data['uid'] = user.uid;
          return data;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Gagal memuat profil Admin: $e");
    }
  }

  Future<void> updateAdminProfile({
    required String fullName,
    required String address,
    required String phoneNumber,
    required String businessType,
    required String bankAccount,
    required String bankName,
    File? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? uploadedImageUrl;

        if (profileImage != null) {
          final storageService = SupabaseStorageService();
          final fileName = 'admin_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          uploadedImageUrl = await storageService.uploadAdminProfileImage(profileImage, fileName);
        }

        final updateData = {
          'fullName': fullName,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessType': businessType,
          'bankAccount': bankAccount,
          'bankName': bankName,
        };

        if (uploadedImageUrl != null) {
          updateData['photoUrl'] = uploadedImageUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      throw Exception("Gagal update profil Admin: $e");
    }
  }

  /// Fetch Admin Stats (Revenue & Monthly Sales)
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      // 1. Get all completed orders for total revenue
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['Paid', 'Shipped', 'Delivered'])
          .get();

      double totalRevenue = 0;
      int monthlySalesUnits = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] as num?)?.toDouble() ?? 0.0;

        // 2. Count monthly units sold
        final createdAt = data['createdAt'];
        DateTime? orderDate;
        if (createdAt is Timestamp) {
          orderDate = createdAt.toDate();
        } else if (createdAt is String) {
          orderDate = DateTime.tryParse(createdAt);
        }

        if (orderDate != null && orderDate.isAfter(firstDayOfMonth)) {
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            monthlySalesUnits += (item['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'monthlySales': monthlySalesUnits,
      };
    } catch (e) {
      debugPrint("Error fetching admin stats: $e");
      return {
        'totalRevenue': 0.0,
        'monthlySales': 0,
      };
    }
  }
}