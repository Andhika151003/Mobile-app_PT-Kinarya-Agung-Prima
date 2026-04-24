import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String? id;
  final String userId;
  final String imgUrl;
  final String orderId;
  final String? productName;
  final String issueType;
  final String description;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolvedByName;

  ComplaintModel({
    this.id,
    required this.userId,
    required this.imgUrl,
    required this.orderId,
    this.productName,
    required this.issueType,
    required this.description,
    this.imageUrls = const [],
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolvedByName,
  });

  factory ComplaintModel.fromMap(String docId, Map<String, dynamic> map) {
    return ComplaintModel(
      id: docId,
      userId: map['userId']?.toString() ?? '',
      imgUrl: map['imgUrl']?.toString() ?? '',
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
      resolvedBy: map['resolvedBy']?.toString(),
      resolvedByName: map['resolvedByName']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imgUrl': imgUrl,
      'orderId': orderId,
      if (productName != null) 'productName': productName,
      'issueType': issueType,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
    };
  }
}