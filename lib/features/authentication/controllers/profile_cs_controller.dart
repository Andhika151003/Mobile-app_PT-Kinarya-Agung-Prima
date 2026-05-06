import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/profile_service.dart';
import '../../../core/repositories/auth_repository.dart';

class ProfileCsController {
  final ProfileService _profileService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileCsController({
    ProfileService? profileService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _profileService = profileService ??
            ProfileService(
              authRepository: AuthRepository(firestore: firestore),
              auth: auth ?? FirebaseAuth.instance,
            );

  Future<Map<String, dynamic>?> getCsProfile() async {
    final result = await _profileService.getProfile();
    return result.isSuccess ? result.data : null;
  }

  Stream<int> getResolvedCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('complaints')
        .where('resolvedBy', isEqualTo: user.uid)
        .where('status', isEqualTo: 'resolved')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}