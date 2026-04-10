import 'admin.dart';
import 'cs.dart';
import 'retailer.dart';

abstract class BaseUser {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;

  BaseUser({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap();

  factory BaseUser.fromMap(String id, Map<String, dynamic> map) {
    String role = map['role']?.toString().toLowerCase() ?? 'retailer';

    if (role == 'admin') {
      return AdminUser.fromMap(id, map);
    } else if (role == 'cs') {
      return CsUser.fromMap(id, map);
    } else {
      return RetailerUser.fromMap(id, map);
    }
  }

  // Abstract copyWith method
  BaseUser copyWith();
}