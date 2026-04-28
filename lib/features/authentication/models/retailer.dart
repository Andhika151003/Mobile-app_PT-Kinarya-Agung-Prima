import 'package:cloud_firestore/cloud_firestore.dart';

class RetailerUser {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;
  final String address;
  final String? storeName;
  final bool isActive;

  RetailerUser({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.createdAt,
    required this.address,
    this.role = 'retailer',
    this.storeName,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': username,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'address': address,
      'storeName': storeName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RetailerUser.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
    }

    return RetailerUser(
      id: id,
      username: map['username'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      password: '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: parsedDate,
      address: map['address'] ?? '',
      storeName: map['storeName'],
      isActive: map['isActive'] ?? true,
    );
  }

  RetailerUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    DateTime? createdAt,
    String? address,
    String? storeName,
  }) {
    return RetailerUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      storeName: storeName ?? this.storeName,
      isActive: isActive ?? this.isActive,
    );
  }
}