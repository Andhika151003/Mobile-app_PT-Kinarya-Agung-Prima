import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardAdminController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardAdminController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getOverviewStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['Paid', 'Shipped', 'Delivered'])
          .get();

      double totalRevenue = 0;
      int totalOrders = ordersSnapshot.docs.length;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] as num?)?.toDouble() ?? 0.0;
      }

      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'retailer')
          .get();
      int totalCustomers = customersSnapshot.docs.length;

      return {
        'totalSales': totalRevenue,
        'salesChange': '+0%',
        'totalOrders': totalOrders,
        'ordersChange': '+0%',
        'totalCustomers': totalCustomers,
        'customersChange': '+0%',
        'conversionRate': totalCustomers > 0 ? (totalOrders / totalCustomers * 100).toStringAsFixed(1) : '0',
        'conversionChange': '+0%',
      };
    } catch (e) {
      throw Exception("Error fetching overview stats: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final snapshot = await _firestore
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception("Error fetching promotions: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getRetailers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'retailer')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception("Error fetching retailers: $e");
    }
  }

  Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          return docSnapshot.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching admin info: $e");
    }
  }
}
