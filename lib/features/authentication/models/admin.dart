import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class AdminUser extends BaseUser {
  final int accessLevel;

  AdminUser({
    super.id,
    required super.username,
    required super.email,
    required super.password,
    required super.phoneNumber,
    required super.createdAt,
    this.accessLevel = 1,
  }) : super(role: 'admin');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': username,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'accessLevel': accessLevel,
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
    );
  }

  @override
  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    DateTime? createdAt,
    int? accessLevel,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      accessLevel: accessLevel ?? this.accessLevel,
    );
  }
}
