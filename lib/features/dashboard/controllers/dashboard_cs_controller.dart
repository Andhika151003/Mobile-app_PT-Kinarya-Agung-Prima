import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardCsController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get complaints statistics
  Future<Map<String, dynamic>> getComplaintStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // TODO: Integrate dengan Firestore untuk data real
      return {
        'openComplaints': 24,
        'resolvedToday': 18,
        'pendingReview': 5,
        'totalResolved': 342,
      };
    } catch (e) {
      throw Exception("Error fetching complaint stats: $e");
    }
  }

  /// Get recent complaints/tickets
  Future<List<Map<String, dynamic>>> getRecentComplaints() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // TODO: Integrate dengan Firestore untuk data real
      return [
        {
          'id': '001',
          'timeAgo': '2h ago',
          'title': 'Wrong Product Delivery',
          'description': "Order #5780 - Product received doesn't\nmatch order specifications",
          'storeName': 'Fresh Food Market',
          'status': 'open',
        },
        {
          'id': '002',
          'timeAgo': '3h ago',
          'title': 'Delayed Delivery',
          'description': 'Order #5781 - Delivery taking longer\nthan estimated time',
          'storeName': 'City Convenience',
          'status': 'open',
        },
      ];
    } catch (e) {
      throw Exception("Error fetching recent complaints: $e");
    }
  }

  /// Get CS profile info
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

  /// Resolve a complaint
  Future<bool> resolveComplaint(String complaintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .update({
            'status': 'resolved',
            'resolvedAt': DateTime.now(),
            'resolvedBy': user.uid,
          });

      return true;
    } catch (e) {
      throw Exception("Error resolving complaint: $e");
    }
  }
}
