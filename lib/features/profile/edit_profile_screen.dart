import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import '../../core/services/user_profile_service.dart';
import '../../core/services/profile_update_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isLoading = true;

  // Controllers
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  String profileImageUrl = '';
  String username = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _statusController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _copyUserId() {
    if (userId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        // Build full address from KTP data
        List<String> addressParts = [];
        if (data.address?.isNotEmpty == true) addressParts.add(data.address!);
        if (data.rt?.isNotEmpty == true) addressParts.add('RT ${data.rt}');
        if (data.rw?.isNotEmpty == true) addressParts.add('RW ${data.rw}');
        if (data.village?.isNotEmpty == true) addressParts.add(data.village!);
        if (data.district?.isNotEmpty == true) addressParts.add(data.district!);
        if (data.city?.isNotEmpty == true) addressParts.add(data.city!);
        if (data.province?.isNotEmpty == true) addressParts.add(data.province!);
        if (data.country?.isNotEmpty == true) addressParts.add(data.country!);

        setState(() {
          _statusController.text = data.status == 'verified'
              ? 'Verified'
              : 'Not Verified';
          _usernameController.text = data.username ?? '';
          _emailController.text = data.email ?? '';
          _phoneController.text = data.phone ?? '';
          _addressController.text = addressParts.join(', ');
          _genderController.text = data.gender ?? '';

          profileImageUrl = data.ktp ?? '';
          username = data.username ?? 'Unknown User';
          userId = data.userId ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CB04C),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Updating profile...',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    try {
      // Get user ID
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User session not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userId = currentUser['code'] as String;

      // Get original profile data
      final profileResult = await UserProfileService.instance.getUserProfile(
        userId,
      );

      if (profileResult['success'] != true) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load profile data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final originalProfile = profileResult['data'];
      bool hasChanges = false;
      bool emailUpdated = false;
      bool phoneUpdated = false;

      // Check if email changed
      if (_emailController.text != originalProfile.email) {
        final result = await ProfileUpdateService.instance.updateEmail(
          userId: userId,
          newEmail: _emailController.text,
        );

        if (result['success'] == true) {
          hasChanges = true;
          emailUpdated = true;
        } else {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update email'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Check if phone changed
      if (_phoneController.text != originalProfile.phone) {
        final result = await ProfileUpdateService.instance.updatePhone(
          userId: userId,
          oldPhone: originalProfile.phone ?? '',
          newPhone: _phoneController.text,
        );

        if (result['success'] == true) {
          hasChanges = true;
          phoneUpdated = true;
        } else {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update phone'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (hasChanges) {
        // Reload profile (cache clearing no longer needed)
        await _loadUserProfile();

        if (mounted) {
          Navigator.of(context).pop();

          // Show different dialog based on what was updated
          if (emailUpdated) {
            _showEmailVerificationDialog();
          } else if (phoneUpdated) {
            DialogHelper.showSuccess(
              context,
              title: 'Success',
              message: 'Phone updated successfully!',
              onConfirm: () {
                Navigator.of(context).pop();
              },
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes detected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CB04C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: Color(0xFF4CB04C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Email Updated Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please check your email to verify your new email address.',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A verification link has been sent to:',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CB04C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(
                          context,
                        ).pop(); // Close edit profile screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB04C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Profile Header
          SizedBox(
            height: 274,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Jakarta Background Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/jakarta_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Gradient Overlay
                Container(
                  height: 205,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CB04C).withOpacity(0.7),
                        const Color(0xFFF8D86E).withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Back Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      return Stack(
                        children: [
                          // Blur Container with User Info
                          Positioned(
                            top: 85,
                            left: (screenWidth - 300) / 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: Container(
                                  width: 300,
                                  height: 145,
                                  padding: const EdgeInsets.only(
                                    top: 65,
                                    bottom: 18,
                                    left: 20,
                                    right: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Username
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Open Sans',
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 2),

                                      // User ID with copy icon
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            userId,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black.withOpacity(
                                                0.7,
                                              ),
                                              fontFamily: 'Open Sans',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _copyUserId,
                                            child: Icon(
                                              Icons.content_copy_outlined,
                                              size: 16,
                                              color: Colors.black.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Profile Picture Circle
                          Positioned(
                            top: 38,
                            left: (screenWidth - 105) / 2,
                            child: Container(
                              width: 105,
                              height: 105,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: profileImageUrl.isNotEmpty
                                    ? Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.person,
                                                  size: 55,
                                                  color: Colors.grey.shade400,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.person,
                                          size: 55,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status
                    TextInput(
                      icon: Icons.verified_user_outlined,
                      hintText: "Status",
                      controller: _statusController,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextInput(
                      icon: Icons.person_outline,
                      hintText: "Username",
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextInput(
                      icon: Icons.email_outlined,
                      hintText: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextInput(
                      icon: Icons.phone_outlined,
                      hintText: "Phone Number",
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Address (without icon)
                    TextInput(
                      hintText: "Address",
                      controller: _addressController,
                      enabled: false,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    TextInput(
                      icon: Icons.wc_outlined,
                      hintText: "Gender",
                      controller: _genderController,
                      enabled: false,
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    AppButton(
                      text: 'Update Profile',
                      onPressed: _updateProfile,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
