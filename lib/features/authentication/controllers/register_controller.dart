import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class RegisterController extends ChangeNotifier {
  final AuthService _authService;

  RegisterController({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  // ==================== VALIDATORS (DELEGATED) ====================

  String? validateFullName(String? value) => Validators.validateFullName(value);
  String? validateEmail(String? value) => Validators.validateEmail(value);
  String? validatePhoneNumber(String? value) => Validators.validatePhoneNumber(value);
  String? validatePassword(String? value) => Validators.validatePassword(value, minLength: 8);
  String? validateConfirmPassword(String? value, String password) => 
      Validators.validateConfirmPassword(value, password);

  // ==================== REGISTER ====================

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String businessType,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      businessType: businessType,
      password: password,
    );

    if (result.isSuccess) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.failure?.message ?? 'Registrasi gagal');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    if (!_isDisposed) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (!_isDisposed) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}