import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../../../supabase_storage_service.dart';
import '../../notification/services/push_notification_service.dart';
import '../../../core/repositories/complaint_repository.dart';

class ComplaintUserController {
  final FirebaseAuth _auth;
  final ComplaintRepository _complaintRepository;
  final SupabaseStorageService _storageService;
  final PushNotificationService _pushNotificationService;

  ComplaintUserController({
    FirebaseAuth? auth,
    ComplaintRepository? complaintRepository,
    SupabaseStorageService? storageService,
    PushNotificationService? pushNotificationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _complaintRepository = complaintRepository ?? ComplaintRepository(),
        _storageService = storageService ?? SupabaseStorageService(),
        _pushNotificationService = pushNotificationService ?? PushNotificationService();

  Future<bool> submitComplaint({
    required String orderId,
    String? productName,
    required String issueType,
    required String description,
    required List<File> images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User belum login');

      List<String> uploadedImageUrls = [];

      if (images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          File imageFile = images[i];
          
          String fileName = 'img_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

          String? imageUrl = await _storageService.uploadComplaintImage(
            imageFile, 
            fileName
          );

          if (imageUrl != null) {
            uploadedImageUrls.add(imageUrl);
          }
        }
      }

      final String imgUrl = uploadedImageUrls.isNotEmpty ? uploadedImageUrls[0] : '';

      final complaint = ComplaintModel(
        userId: user.uid,
        imgUrl: imgUrl,
        orderId: orderId,
        productName: productName,
        issueType: issueType,
        description: description,
        imageUrls: uploadedImageUrls,
        status: 'pending', 
        createdAt: DateTime.now(),
      );

      await _complaintRepository.addComplaint(complaint);

      await _pushNotificationService.sendNotificationToAdmin(
        title: 'Komplain Baru!',
        message: 'Ada komplain baru untuk pesanan $orderId: $issueType.',
        type: 'complaint',
        relatedId: orderId,
      );

      return true;
    } catch (e) {
      debugPrint('Error submit complaint: $e');
      return false;
    }
  }

  Stream<List<ComplaintModel>> getUserComplaints() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _complaintRepository.getUserComplaintsStream(user.uid);
  }
}