import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class CsUser extends BaseUser {
  final String department;
  final int handledTickets;

  CsUser({
    super.id,
    required super.username,
    required super.email,
    required super.password,
    required super.phoneNumber,
    required super.createdAt,
    this.department = 'General',
    this.handledTickets = 0,
  }) : super(role: 'cs');

  @override
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
    );
  }

  @override
  CsUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    DateTime? createdAt,
    String? department,
    int? handledTickets,
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
    );
  }
}
