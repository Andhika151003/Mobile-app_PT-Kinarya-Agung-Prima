import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;
  final int accessLevel;
  final bool isActive;

  AdminUser({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.createdAt,
    this.role = 'admin',
    this.accessLevel = 1,
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
      'accessLevel': accessLevel,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdminUser.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
    }

    return AdminUser(
      id: id,
      username: map['username'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      password: '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: parsedDate,
      accessLevel: map['accessLevel'] ?? 1,
      isActive: map['isActive'] ?? true,
    );
  }

  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    DateTime? createdAt,
    int? accessLevel,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      accessLevel: accessLevel ?? this.accessLevel,
      isActive: isActive ?? this.isActive,
    );
  }
}
