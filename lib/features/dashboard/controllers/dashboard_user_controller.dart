import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../product/models/product.dart';

class DashboardUserController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardUserController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

  Future<String> getUserFullName() async {
    try {
      final userData = await getUserData();
      return userData?['fullName'] ?? 'Retailer';
    } catch (e) {
      throw Exception("Error getting user name: $e");
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['Paid', 'Shipped', 'Delivered'])
          .get();

      double totalSpent = 0;
      int totalOrders = ordersSnapshot.docs.length;

      for (var doc in ordersSnapshot.docs) {
        totalSpent += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception("Error fetching dashboard stats: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getRecentOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<ProductModel>> getRecommendedProducts() {
    return _firestore
        .collection('products')
        .orderBy('monthlySales', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
