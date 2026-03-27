import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';
import 'register_view.dart';
import 'home_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> _handleLogin(LoginController controller) async {
    if (_formKey.currentState!.validate()) {
      final user = await controller.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        String route;
        switch (user.role) {
          case 'admin':
            route = '/admin_dashboard';
            break;
          case 'customer_support':
            route = '/cs_dashboard';
            break;
          default:
            route = '/home';
        }

        Navigator.pushReplacementNamed(context, route);
      } else if (mounted && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Consumer<LoginController>(
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
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
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
                        'Sign in to continue to your account',
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

                    // ==================== EMAIL FIELD ====================
                    const Text(
                      'Email',  // ← SUDAH DIGANTI DARI "Username"
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Enter your email'),
                      validator: controller.validateEmailInput,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    if (controller.errorMessage == 'Email not found')
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              controller.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ==================== PASSWORD FIELD ====================
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
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration('Enter your password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: controller.validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    if (controller.errorMessage == 'Incorrect password')
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              controller.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur forgot password akan segera hadir'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () => _handleLogin(controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
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
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterView(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: Color(0xFF2E7D32),
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
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
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
    _passwordController.dispose();
    super.dispose();
  }
}