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
              data['orderId'] = doc.id;
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

  Stream<OrderModel?> streamOrderById(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      var data = doc.data()!;
      data['orderId'] = doc.id;
      return OrderModel.fromMap(data);
    });
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersStreamByUserId(String userId) {
    return _ordersCollection.where('userId', isEqualTo: userId).snapshots();
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

  Future<void> processOrderPaymentAndStats(String orderId, {String? targetStatus}) async {
    final orderRef = _ordersCollection.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;

      final data = orderDoc.data()!;
      final itemsData = data['items'] as List<dynamic>? ?? [];

      final updates = _calculateStatusUpdates(data, targetStatus);

      final bool statsRecorded = data['statsRecorded'] ?? false;
      if (!statsRecorded) {
        await _recordProductStats(transaction, itemsData);
        updates['statsRecorded'] = true;
      }

      if (updates.isNotEmpty) {
        transaction.update(orderRef, updates);
      }
    });
  }

  Map<String, dynamic> _calculateStatusUpdates(Map<String, dynamic> data, String? targetStatus) {
    final currentStatus = data['status']?.toString() ?? '';
    Map<String, dynamic> updates = {};

    if (targetStatus != null) {
      updates['status'] = targetStatus;
      if (targetStatus == 'Paid') updates['paidAt'] = FieldValue.serverTimestamp();
      if (targetStatus == 'Shipped') updates['shippedAt'] = FieldValue.serverTimestamp();
      if (targetStatus == 'Delivered') updates['deliveredAt'] = FieldValue.serverTimestamp();
    } else {
      const finalStatuses = ['Paid', 'Shipped', 'Delivered', 'Cancelled', 'Expired'];
      if (!finalStatuses.contains(currentStatus)) {
        updates['status'] = 'Paid';
        updates['paidAt'] = FieldValue.serverTimestamp();
      }
    }
    return updates;
  }

  Future<void> _recordProductStats(Transaction transaction, List<dynamic> itemsData) async {
    // 1. First, perform all READS (gets)
    final Map<DocumentReference, DocumentSnapshot> productDocs = {};
    for (var itemMap in itemsData) {
      final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
      if (productId == null) continue;

      final pRef = _firestore.collection('products').doc(productId);
      if (!productDocs.containsKey(pRef)) {
        productDocs[pRef] = await transaction.get(pRef);
      }
    }

    // 2. Then, perform all WRITES (updates)
    for (var itemMap in itemsData) {
      final productId = itemMap['productId']?.toString() ?? itemMap['id']?.toString();
      if (productId == null) continue;

      final pRef = _firestore.collection('products').doc(productId);
      final pDoc = productDocs[pRef];

      if (pDoc != null && pDoc.exists) {
        final int quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
        final double price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
        
        if (quantity > 0) {
          transaction.update(pRef, {
            'monthlySales': FieldValue.increment(quantity),
            'revenue': FieldValue.increment((price * quantity).toInt()),
            'stock': FieldValue.increment(-quantity),
          });
        }
      }
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getOrdersSince(DateTime? startDate) {
    Query query = _firestore.collection('orders');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    return query.get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }
}
