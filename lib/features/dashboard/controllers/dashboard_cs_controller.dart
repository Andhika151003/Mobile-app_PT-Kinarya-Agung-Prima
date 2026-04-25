import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../complaint/models/complaint.dart';

class DashboardCsController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DashboardCsController({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<Map<String, int>> getComplaintStatsStream() {
    return _firestore.collection('complaints').snapshots().map((snapshot) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      int open = 0;
      int resolvedToday = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        
        if (status == 'pending') {
          open++;
        } else if (status == 'resolved') {
          final resolvedAt = data['resolvedAt'];
          if (resolvedAt is Timestamp) {
            final date = resolvedAt.toDate();
            if (date.isAfter(startOfToday)) {
              resolvedToday++;
            }
          }
        }
      }
      
      return {
        'openComplaints': open,
        'resolvedToday': resolvedToday,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getRecentComplaintsStream() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final complaint = ComplaintModel.fromMap(doc.id, doc.data());
        return {
          'id': complaint.id,
          'timeAgo': _formatTimeAgo(complaint.createdAt),
          'title': complaint.issueType,
          'description': complaint.description,
          'storeName': complaint.productName ?? 'Order #${complaint.orderId}',
          'status': complaint.status,
          'model': complaint,
        };
      }).toList();
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 7) {
      return DateFormat('dd MMM yyyy').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<Map<String, dynamic>?> getCsInfo() async {
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
      throw Exception("Error fetching CS info: $e");
    }
  }

  Future<bool> resolveComplaint(String complaintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get CS Name
      final csDoc = await _firestore.collection('users').doc(user.uid).get();
      final csName = csDoc.data()?['fullName'] ?? 'Customer Service';

      await _firestore.collection('complaints').doc(complaintId).update({
        'status': 'resolved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': user.uid,
        'resolvedByName': csName,
      });

      return true;
    } catch (e) {
      throw Exception("Error resolving complaint: $e");
    }
  }

  Future<bool> rejectComplaint(String complaintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get CS Name
      final csDoc = await _firestore.collection('users').doc(user.uid).get();
      final csName = csDoc.data()?['fullName'] ?? 'Customer Service';

      await _firestore.collection('complaints').doc(complaintId).update({
        'status': 'rejected',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': user.uid,
        'resolvedByName': csName,
      });

      return true;
    } catch (e) {
      throw Exception("Error rejecting complaint: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }
}
