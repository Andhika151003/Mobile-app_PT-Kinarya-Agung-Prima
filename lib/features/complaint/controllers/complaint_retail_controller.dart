import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../../../supabase_storage_service.dart';

class ComplaintUserController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseStorageService _storageService = SupabaseStorageService();

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

      await _firestore.collection('complaints').add(complaint.toMap());

      return true;
    } catch (e) {
      debugPrint('Error submit complaint: $e');
      return false;
    }
  }

  Stream<List<ComplaintModel>> getUserComplaints() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.id, doc.data()))
              .toList();
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }
}