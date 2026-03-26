import 'package:flutter/material.dart';
import '../models/retailer.dart';
import 'register_controller.dart';

class LoginController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Retailer> get _users => RegisterController.tempRetailers;

  // Validasi untuk field "Username" (sebenarnya diisi email)
  String? validateEmailInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Validasi format email sederhana
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<Retailer?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Cari user berdasarkan email
      final user = _users.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('Email not found'),
      );

      // Validasi password
      if (user.password != password) {
        throw Exception('Incorrect password');
      }

      _setLoading(false);
      return user;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
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