import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/order/models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              var data = doc.data();
              data['orderId'] = doc.id; // Ensure ID is present
              return OrderModel.fromMap(data);
            })
            .toList());
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;
    var data = doc.data()!;
    data['orderId'] = doc.id;
    return OrderModel.fromMap(data);
  }

  Future<void> updateOrderStatus(String orderId, Map<String, dynamic> data) async {
    await _ordersCollection.doc(orderId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrder(Map<String, dynamic> data) async {
    final orderId = data['orderId'];
    if (orderId == null) throw Exception("Order ID is required");
    
    await _ordersCollection.doc(orderId).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<OrderModel>> getAllOrders() async {
    final snapshot = await _ordersCollection.get();
    return snapshot.docs
        .map((doc) {
          var data = doc.data();
          data['orderId'] = doc.id;
          return OrderModel.fromMap(data);
        })
        .toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getOrdersByUserId(String userId) async {
    return await _ordersCollection.where('userId', isEqualTo: userId).get();
  }

  Stream<List<OrderModel>> getRecentOrdersStream(String userId, {int limit = 5}) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              var data = doc.data();
              data['orderId'] = doc.id;
              return OrderModel.fromMap(data);
            })
            .toList());
  }
}
