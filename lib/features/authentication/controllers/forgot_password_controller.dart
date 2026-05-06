import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ForgotPasswordController({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  String? validateEmail(String? value) => Validators.validateEmail(value);

  Future<bool> isEmailRegistered(String email) async {
    final result = await _authService.isEmailRegistered(email);
    return result.isSuccess && (result.data ?? false);
  }

  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.forgotPassword(email);
      if (!result.isSuccess) {
        throw Exception(result.failure?.message ?? 'Gagal mengirim email reset');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
