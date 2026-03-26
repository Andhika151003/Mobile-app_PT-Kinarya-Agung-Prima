class Retailer {
  final String? id;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String address;
  final String role;
  final DateTime createdAt;

  Retailer({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.address,
    this.role = 'retailer',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Retailer.fromMap(String id, Map<String, dynamic> map) {
    return Retailer(
      id: id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      password: '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'retailer',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Retailer copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    String? phoneNumber,
    String? address,
    String? role,
    DateTime? createdAt,
  }) {
    return Retailer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}