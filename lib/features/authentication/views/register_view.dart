import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/register_controller.dart';
import 'login_view.dart';
import 'verify_email_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedBusinessType;
  final List<String> _businessTypes = [
    'Pet Shop',
    'Skincare',
    'UD (Usaha Dagang)',
    'Toko Kelontong / Perseorangan',
    'Lainnya'
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;



  Future<void> _handleRegister(RegisterController controller) async {
    if (_formKey.currentState!.validate()) {
      final success = await controller.register(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        businessType: _selectedBusinessType ?? 'Lainnya',
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VerifyEmailView(),
          ),
        );
      } else if (mounted && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Consumer<RegisterController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Center(
                      child: Text(
                        'Create a retailer account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Enter your email to sign up for this app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_email',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 255,
                        decoration: _inputDecoration('Enter your email'),
                        validator: controller.validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_fullname',
                      child: TextFormField(
                        controller: _fullNameController,
                        maxLength: 100,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                        decoration: _inputDecoration('Enter your full name'),
                        validator: controller.validateFullName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Business Type Field (Dropdown)
                    const Text(
                      'Business Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_business_type',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBusinessType,
                        items: _businessTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(fontSize: 14, fontFamily: 'Inter')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBusinessType = value;
                          });
                        },
                        decoration: _inputDecoration('Select business type'),
                        validator: (value) => value == null ? 'Please select your business type' : null,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_phone',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration('Contoh: 8123456789')
                            .copyWith(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Text(
                              '+62',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                        validator: controller.validatePhoneNumber,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Address Field
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_address',
                      child: TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        maxLength: 255,
                        decoration: _inputDecoration('Enter your address'),
                        validator: controller.validateAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_password',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        maxLength: 64,
                        decoration: _inputDecoration('Create a password').copyWith(
                          suffixIcon: IconButton(
                          icon: Semantics(
                            label: 'btn_register_password_visibility',
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                            ),
                          ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => controller.validatePassword(value),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'input_register_confirm_password',
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        maxLength: 64,
                        decoration: _inputDecoration('Confirm your password').copyWith(
                          suffixIcon: IconButton(
                          icon: Semantics(
                            label: 'btn_register_confirm_password_visibility',
                            child: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                            ),
                          ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => controller.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Semantics(
                        label: 'btn_register_submit',
                        child: ElevatedButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => _handleRegister(controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Semantics(
                          label: 'btn_register_to_login',
                          button: true,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginView(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        color: Colors.grey[400],
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}