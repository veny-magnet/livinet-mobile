import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';

class ProfileHeader extends StatefulWidget {
  final VoidCallback? onRefresh;

  const ProfileHeader({super.key, this.onRefresh});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  UserProfile? _profile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _profile = result['data'] as UserProfile;
          _isLoading = false;
        });

        // Call onRefresh callback if provided
        widget.onRefresh?.call();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  void _copyUserId() {
    if (_profile?.userId != null) {
      Clipboard.setData(ClipboardData(text: _profile!.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Public method to refresh profile from outside
  void refreshProfile() {
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    // Blur Container with User Info
                    Positioned(
                      top: 85, // Reduced from 88 to 85
                      left: (screenWidth - 300) / 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: 300,
                            height: 145, // Reduced from 150 to 145
                            padding: const EdgeInsets.only(
                              top: 65, // Reduced from 70 to 65
                              bottom: 18, // Reduced from 20 to 18
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
                                _isLoading
                                    ? Container(
                                        width: 120,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _profile?.username ?? 'Unknown User',
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
                                _isLoading
                                    ? Container(
                                        width: 80,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _profile?.userId ?? 'Unknown ID',
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

                                // Error message with retry if any
                                if (_errorMessage.isNotEmpty && !_isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Failed to load profile',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade600,
                                            fontFamily: 'Open Sans',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: _loadProfile,
                                          child: Text(
                                            'Tap to retry',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade600,
                                              fontFamily: 'Open Sans',
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Profile Picture Circle
                    Positioned(
                      top: 38, // Reduced from 40 to 38
                      left: (screenWidth - 105) / 2, // Reduced from 110 to 105
                      child: Container(
                        width: 105, // Reduced from 110 to 105
                        height: 105, // Reduced from 110 to 105
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/profile-photo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 55, // Reduced from 60 to 55
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
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
    );
  }
}
