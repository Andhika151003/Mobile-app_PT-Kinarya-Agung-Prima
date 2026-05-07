import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService;

  LoginController({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _deactivatedAdminPhone;
  String? get deactivatedAdminPhone => _deactivatedAdminPhone;

  bool _isDisposed = false;
  
  // ==================== VALIDATORS (DELEGATED) ====================
  
  String? validateEmailInput(String? value) => Validators.validateEmail(value);
  String? validatePassword(String? value) => Validators.validatePassword(value);

  // ==================== LOGIN ====================

  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    _deactivatedAdminPhone = null;

    final result = await _authService.login(email: email, password: password);

    if (result.isSuccess) {
      _setLoading(false);
      return result.data;
    } else {
      final failure = result.failure;
      _setError(failure?.message ?? 'Login gagal');
      
      if (failure?.message.contains('hubungi admin di') ?? false) {
        final parts = failure!.message.split(' di ');
        if (parts.length > 1) {
          _deactivatedAdminPhone = parts[1].replaceAll('.', '');
        }
      }
      
      _setLoading(false);
      return null;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    await _authService.logout();
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
