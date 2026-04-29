import 'package:cloud_firestore/cloud_firestore.dart';

class CsUser {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;
  final String department;
  final int handledTickets;
  final bool isActive;

  CsUser({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.createdAt,
    this.role = 'cs',
    this.department = 'General',
    this.handledTickets = 0,
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
      'department': department,
      'handledTickets': handledTickets,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CsUser.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
    }

    return CsUser(
      id: id,
      username: map['username'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      password: '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: parsedDate,
      department: map['department'] ?? 'General',
      handledTickets: map['handledTickets'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  CsUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    DateTime? createdAt,
    String? department,
    int? handledTickets,
    bool? isActive,
  }) {
    return CsUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      handledTickets: handledTickets ?? this.handledTickets,
      isActive: isActive ?? this.isActive,
    );
  }
}
