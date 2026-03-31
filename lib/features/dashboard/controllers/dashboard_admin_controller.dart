import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardAdminController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get overview stats (total sales, orders, customers)
  Future<Map<String, dynamic>> getOverviewStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // TODO: Integrate dengan Firestore data untuk statistik real
      return {
        'totalSales': '\$10,000',
        'salesChange': '+20%',
        'totalOrders': 850,
        'ordersChange': '+8.2%',
        'totalCustomers': 1200,
        'customersChange': '+4.5%',
        'conversionRate': 65.5,
        'conversionChange': '+2.3%',
      };
    } catch (e) {
      throw Exception("Error fetching overview stats: $e");
    }
  }

  /// Get list of active promotions
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

  /// Get list of retailers managed by admin
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

  /// Get admin profile info
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
