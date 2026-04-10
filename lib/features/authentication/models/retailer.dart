import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class RetailerUser extends BaseUser {
  final String address;
  final String? storeName;

  RetailerUser({
    super.id,
    required super.username,
    required super.email,
    required super.password,
    required super.phoneNumber,
    required super.createdAt,
    required this.address,
    this.storeName,
  }) : super(role: 'retailer');

  @override
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
    );
  }

  @override
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
    );
  }
}