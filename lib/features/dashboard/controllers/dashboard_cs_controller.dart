import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../authentication/services/profile_service.dart';
import '../../../core/repositories/complaint_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';

class DashboardCsController {
  final ProfileService _profileService;
  final ComplaintRepository _complaintRepository;
  final FirebaseAuth _auth;
  final FirebaseFirestore? _firestore; // Kept for some direct calls if needed, but primarily for repo initialization

  DashboardCsController({
    ProfileService? profileService,
    ComplaintRepository? complaintRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore,
        _profileService = profileService ??
            ProfileService(
              authRepository: AuthRepository(firestore: firestore),
              auth: auth ?? FirebaseAuth.instance,
            ),
        _complaintRepository =
            complaintRepository ?? ComplaintRepository(firestore: firestore);

  Stream<Map<String, int>> getComplaintStatsStream() {
    return _complaintRepository.getComplaintsSnapshotStream().map((snapshot) {
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
    return _complaintRepository.getRecentComplaintsStream().map((complaints) {
      return complaints.map((complaint) {
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
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Future<bool> resolveComplaint(String complaintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Result<Map<String, dynamic>?> csProfileResult = await _profileService.getProfile();
      final csName = csProfileResult.isSuccess ? (csProfileResult.data?['fullName'] ?? 'CS') : 'CS';

      await _complaintRepository.updateComplaint(complaintId, {
        'status': 'resolved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': user.uid,
        'resolvedByName': csName,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectComplaint(String complaintId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Result<Map<String, dynamic>?> csProfileResult = await _profileService.getProfile();
      final csName = csProfileResult.isSuccess ? (csProfileResult.data?['fullName'] ?? 'CS') : 'CS';

      await _complaintRepository.updateComplaint(complaintId, {
        'status': 'rejected',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': user.uid,
        'resolvedByName': csName,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
