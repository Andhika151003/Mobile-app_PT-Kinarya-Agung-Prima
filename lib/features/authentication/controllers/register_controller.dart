import 'package:flutter/material.dart';
import '../models/retailer.dart';
import '../services/seed_data.dart';

class RegisterController extends ChangeNotifier {
  static final List<Retailer> _tempRetailers = [];
  static bool _seeded = false;

  static List<Retailer> get tempRetailers {
    _ensureSeeded();
    return _tempRetailers;
  }

  static void _ensureSeeded() {
    if (!_seeded) {
      SeedData.seedInitialData(_tempRetailers);
      _seeded = true;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==================== VALIDATORS ====================

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full Name is required';
    }
    if (value.trim().length < 3) {
      return 'Please enter a full name';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    if (isEmailRegistered(value)) {
      return 'Email already registered';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone Number is required';
    }
    final phoneDigits = value.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 13) {
      return 'Please enter valid phone number';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current address';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ==================== BUSINESS LOGIC ====================

  bool isEmailRegistered(String email) {
    _ensureSeeded();
    return _tempRetailers.any((retailer) => retailer.email == email);
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      final newRetailer = Retailer(
        id: tempId,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        address: address.trim(),
        password: password,
        role: 'retailer',
        createdAt: DateTime.now(),
      );

      _tempRetailers.add(newRetailer);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Registrasi gagal: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  static List<Retailer> getAllUsers() {
    _ensureSeeded();
    return _tempRetailers;
  }

  static void clearTempUsers() {
    _tempRetailers.clear();
    _seeded = false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}