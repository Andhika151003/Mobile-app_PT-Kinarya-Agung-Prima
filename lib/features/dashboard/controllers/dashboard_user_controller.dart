import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../product/models/product.dart';

class DashboardUserController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardUserController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch user data untuk dashboard
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          var data = docSnapshot.data() as Map<String, dynamic>;
          data['uid'] = user.uid;
          return data;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching user data: $e");
    }
  }

  /// Get user full name untuk greeting
  Future<String> getUserFullName() async {
    try {
      final userData = await getUserData();
      return userData?['fullName'] ?? 'Retailer';
    } catch (e) {
      throw Exception("Error getting user name: $e");
    }
  }

  /// Get dashboard overview stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // TODO: Integrate dengan data produk/order dari Firestore
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'totalRevenue': 0.0,
        'recentNotifications': [],
      };
    } catch (e) {
      throw Exception("Error fetching dashboard stats: $e");
    }
  }

  /// Get recommended products (Admin's supply products)
  Stream<List<ProductModel>> getRecommendedProducts() {
    return _firestore
        .collection('products')
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
