import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0 = enter email, 1 = enter OTP, 2 = reset password
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(5, (_) => TextEditingController());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _timer;
  int _secondsRemaining = 30;

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _sendOtp() {
    if (_emailController.text.isEmpty) return;
    setState(() => _step = 1);
    _startTimer();
  }

  void _resendOtp() {
    debugPrint("Resending OTP...");
    _startTimer(); // restart countdown
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    debugPrint("Verifying OTP: $otp");
    // TODO: Add verification logic
    setState(() => _step = 2); // go to reset password step
  }

  void _changePassword() {
    debugPrint("New password: ${_passwordController.text}");
    debugPrint("Confirm password: ${_confirmPasswordController.text}");
    // TODO: Add change password logic
    context.go('/login');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  text: "Send OTP Code",
                  onPressed: _sendOtp,
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
                  text: "Verify OTP",
                  onPressed: _verifyOtp,
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
                                text: "$_secondsRemaining s",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        )
                      : GestureDetector(
                          onTap: _resendOtp,
                          child: Text(
                            "Resend Code",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.secondary,
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
                  text: "Change Password",
                  onPressed: _changePassword,
                  isPrimary: true,
                ),
              ],
            ],
          ),
        ),
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
