import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String? id; // ID Dokumen Firestore
  final String userId;
  final String orderId;
  final String? productName;
  final String issueType;
  final String description;
  final List<String> imageUrls;
  final String status; // Contoh: 'pending', 'investigating', 'resolved', 'rejected'
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    this.id,
    required this.userId,
    required this.orderId,
    this.productName,
    required this.issueType,
    required this.description,
    this.imageUrls = const [],
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
  });

  // Konversi dari Firestore ke Objek Dart
  factory ComplaintModel.fromMap(String docId, Map<String, dynamic> map) {
    return ComplaintModel(
      id: docId,
      userId: map['userId']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      productName: map['productName']?.toString(),
      issueType: map['issueType']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: map['status']?.toString() ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null 
          ? (map['resolvedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Konversi dari Objek Dart ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderId': orderId,
      if (productName != null) 'productName': productName,
      'issueType': issueType,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}