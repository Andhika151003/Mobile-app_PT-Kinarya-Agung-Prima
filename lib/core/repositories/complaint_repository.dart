import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/complaint/models/complaint.dart';

class ComplaintRepository {
  final FirebaseFirestore _firestore;

  ComplaintRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ComplaintModel>> getAllComplaintsStream() {
    return _firestore.collection('complaints').snapshots().map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.id, doc.data()))
          .toList();
      complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return complaints;
    });
  }

  Stream<List<ComplaintModel>> getRecentComplaintsStream({int limit = 20}) {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _firestore.collection('complaints').doc(id).update(data);
  }

  Future<void> addComplaint(ComplaintModel complaint) async {
    await _firestore.collection('complaints').add(complaint.toMap());
  }

  Stream<List<ComplaintModel>> getUserComplaintsStream(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.id, doc.data()))
          .toList();
      complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return complaints;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getComplaintsSnapshotStream() {
    return _firestore.collection('complaints').snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getComplaintsSince(DateTime? startDate) {
    Query query = _firestore.collection('complaints');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    return query.get() as Future<QuerySnapshot<Map<String, dynamic>>>;
  }
}
