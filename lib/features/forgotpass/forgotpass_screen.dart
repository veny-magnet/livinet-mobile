import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/services/forgot_password_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  String get _timerDisplay {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(1, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  int _step = 0; // 0 = enter email, 1 = enter OTP, 2 = reset password
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(5, (_) => TextEditingController());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _loadingMessage = '';
  
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();

  Timer? _timer;
  int _secondsRemaining = 300;

  void _startTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }
    
    if (!_forgotPasswordService.isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Sending OTP...';
    });
    
    try {
      final result = await _forgotPasswordService.sendOTP(email: email);
      
      if (result['success']) {
        _showSuccess('OTP sent to your email successfully');
        setState(() => _step = 1);
        _startTimer();
      } else {
        _showError(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showError('Error sending OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Resending OTP...';
    });
    
    try {
      final result = await _forgotPasswordService.sendOTP(email: _emailController.text.trim());
      
      if (result['success']) {
        _showSuccess('OTP resent successfully');
        _startTimer();
      } else {
        _showError(result['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      _showError('Error resending OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
  
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Verifying OTP';
    });
    
    try {
      final result = await _forgotPasswordService.verifyOTP(
        email: _emailController.text.trim(),
        otp: otp,
      );
      
      if (result['success']) {
        _showSuccess('OTP verified successfully');
        setState(() => _step = 2);
        _timer?.cancel();
      } else {
        _showError(result['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showError('Error verifying OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in both password fields');
      return;
    }
    
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }
    
    final passwordValidation = _forgotPasswordService.validatePassword(password);
    if (!passwordValidation['isValid']) {
      final errors = passwordValidation['errors'] as Map<String, String>;
      _showError(errors.values.first);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Updating password...';
    });
    
    try {
      final otp = _otpControllers.map((c) => c.text).join();
      final result = await _forgotPasswordService.resetPasswordWithOTP(
        email: _emailController.text.trim(),
        otp: otp,
        newPassword: password,
      );
      
      if (result['success']) {
        _showSuccess('Password reset successfully!');
        
        // Navigate to login after short delay
        Future.delayed(const Duration(seconds: 2), () {
          context.go('/login');
        });
      } else {
        _showError(result['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _showError('Error resetting password: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // --- HEADER with back + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _step >= 0 ? c.secondary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _step >= 1 ? c.secondary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _step >= 2 ? c.secondary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // --- Placeholder Image (square)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 1, // square
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // --- STEP CONTENT
              if (_step == 0) ...[
                Text(
                  "Please enter your email address to receive a verification code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 26),
                TextInput(
                  icon: Icons.email_outlined,
                  hintText: "Email",
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: _isLoading ? "Sending..." : "Send OTP Code",
                  onPressed: _isLoading ? null : _sendOtp,
                  isPrimary: true,
                ),
              ] else if (_step == 1) ...[
                Text.rich(
                  TextSpan(
                    text: "Please enter the code that we sent to ",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(
                        text: _emailController.text,
                        style: TextStyle(
                          color: c.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // OTP Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    return SizedBox(
                      width: 45,
                      child: TextField(
                        controller: _otpControllers[i],
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 4) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),
                AppButton(
                  text: _isLoading ? "Verifying..." : "Verify OTP",
                  onPressed: _isLoading ? null : _verifyOtp,
                  isPrimary: true,
                ),
                const SizedBox(height: 24),

                // --- Resend Text
                Center(
                  child: _secondsRemaining > 0
                      ? Text.rich(
                          TextSpan(
                            text: "You can resend the code in ",
                            style: TextStyle(
                              fontSize: 14,
                              color: c.onSurface.withOpacity(0.7),
                            ),
                            children: [
                              TextSpan(
                                text: _timerDisplay,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        )
                      : GestureDetector(
                          onTap: _isLoading ? null : _resendOtp,
                          child: Text(
                            _isLoading ? "Resending..." : "Resend Code",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isLoading ? Colors.grey : c.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ] else if (_step == 2) ...[
                Text(
                  "Please enter your new password and confirmation password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 26),

                // New Password
                _buildPasswordField(
                  controller: _passwordController,
                  hint: "Password",
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  c: c,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: "Confirmation Password",
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  c: c,
                ),
                const SizedBox(height: 30),

                AppButton(
                  text: _isLoading ? "Updating..." : "Change Password",
                  onPressed: _isLoading ? null : _changePassword,
                  isPrimary: true,
                ),
              ],
                  ],
                ),
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required ColorScheme c,
  }) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: c.primary),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
