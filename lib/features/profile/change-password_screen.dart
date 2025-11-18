import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/profile_update_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_input.dart' as custom_widgets;
import '../../core/widgets/confirmation_dialog.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Password strength variables

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String password = _newPasswordController.text;
    // Password strength logic - just checking without storing unused variables
    if (password.isEmpty) {
      // No action needed
    } else if (password.length < 6) {
      // Very weak
    } else if (password.length < 8) {
      // Weak
    } else {
      // Check for various criteria
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasLowercase = password.contains(RegExp(r'[a-z]'));
      bool hasDigits = password.contains(RegExp(r'[0-9]'));
      bool hasSpecialCharacters = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );

      int criteriaCount = 0;
      if (hasUppercase) criteriaCount++;
      if (hasLowercase) criteriaCount++;
      if (hasDigits) criteriaCount++;
      if (hasSpecialCharacters) criteriaCount++;

      if (criteriaCount >= 3 && password.length >= 8) {
        // Very strong
      } else if (criteriaCount >= 2) {
        // Strong
      } else {
        // Medium
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Get user ID from AuthService
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('User session not found. Please login again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = currentUser['code'] as String;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Call the manual password change API (not reset)
      final result = await ProfileUpdateService.instance.changePassword(
        userId: userId,
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        if (result['success'] == true) {
          // Show success dialog using DialogHelper
          DialogHelper.showSuccess(
            context,
            title: 'Success',
            message: result['message'] ?? 'Password changed successfully!',
            onConfirm: () {
              Navigator.of(context).pop();
            },
          );

          // Clear form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          // Show error message
          DialogHelper.showError(
            context,
            title: 'Error',
            message: result['message'] ?? 'Failed to change password',
            onConfirm: () {},
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Dialog might not be open
        }
      }

      if (mounted) {
        DialogHelper.showError(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
          onConfirm: () {},
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        titleSpacing: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Change Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Current Password
              custom_widgets.TextInput(
                icon: Icons.lock_outline,
                hintText: "Current Password",
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFA5A9A9),
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // New Password
              custom_widgets.TextInput(
                icon: Icons.lock_outline,
                hintText: "New Password",
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFA5A9A9),
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              custom_widgets.TextInput(
                icon: Icons.lock_outline,
                hintText: "Confirm New Password",
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFA5A9A9),
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Change Password Button
              AppButton(
                text: _isLoading ? 'Changing...' : 'Change Password',
                onPressed: _isLoading ? null : _changePassword,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
