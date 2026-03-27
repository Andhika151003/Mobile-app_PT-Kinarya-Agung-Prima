class User {
  final String? userId;
  final String username;
  final String email;
  final String password; 
  final String role; 
  final String phoneNumber;

  User({
    this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      userId: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: '',
      role: map['role'] ?? 'retailer',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  User copyWith({
    String? userId,
    String? username,
    String? email,
    String? password,
    String? role,
    String? phoneNumber,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}