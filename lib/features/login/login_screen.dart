import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/app_initializer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = '';
  final AuthService _authService = AuthService();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Open Sans',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _onLogin(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Signing in';
    });

    try {
      String fcmToken = await FcmService.getTokenForRegistration();

      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fcmToken: fcmToken,
      );

      if (result['success']) {
        // Initialize app data in parallel
        setState(() => _loadingMessage = 'Signing in');

        final initResult = await AppInitializer.instance.initialize();

        // Subscribe to push notification topics after successful login
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null && currentUser['code'] != null) {
          setState(() => _loadingMessage = 'Signing in');
        }

        if (initResult['success']) {
          _showSuccess('Login successful!');
          context.go('/home');
        }
      } else {
        // Show error message using snackbar
        _showError(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);
    final c = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/top_gradient.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: screenHeight * 0.35,
            ),
          ),

          Positioned(
            bottom: -30,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/bottom_gradient.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: screenHeight * 0.35,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Login to your account",
                    style: TextStyle(fontSize: 14, color: c.onSurface),
                    textAlign: TextAlign.left,
                  ),

                  const Spacer(),

                  TextInput(
                    icon: Icons.email_outlined,
                    hintText: "Email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: borderColor,
                        ),
                        hintText: "Password",
                        hintStyle: const TextStyle(color: borderColor),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: c.primary),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: borderColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.go('/forgotpass');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  AppButton(
                    text: _isLoading ? "Signing in..." : "Login",
                    onPressed: _isLoading ? null : () => _onLogin(context),
                    isPrimary: true,
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: c.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          debugPrint("Sign Up tapped");
                          context.go('/signup');
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
