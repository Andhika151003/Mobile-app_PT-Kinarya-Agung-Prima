import '../models/retailer.dart';

class SeedData {
  static final List<Retailer> defaultUsers = [
    Retailer(
      id: 'admin_001',
      fullName: 'System Administrator',
      email: 'admin@kinarya.com',
      password: 'admin123',
      phoneNumber: '081234567890',
      address: 'Head Office',
      role: 'admin',
      createdAt: DateTime.now(),
    ),
    Retailer(
      id: 'cs_001',
      fullName: 'Customer Support Team',
      email: 'cs@kinarya.com',
      password: 'cs123',
      phoneNumber: '081234567891',
      address: 'Customer Service Center',
      role: 'customer_support',
      createdAt: DateTime.now(),
    ),
  ];

  static void seedInitialData(List<Retailer> storage) {
    for (var user in defaultUsers) {
      final exists = storage.any((u) => u.email == user.email);
      if (!exists) {
        storage.add(user);
      }
    }
  }
}