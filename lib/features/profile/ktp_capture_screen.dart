import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ktp_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/app_button.dart';
import 'ktp_review_screen.dart';

class KtpCaptureScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const KtpCaptureScreen({super.key, required this.registrationData});

  @override
  State<KtpCaptureScreen> createState() => _KtpCaptureScreenState();
}

class _KtpCaptureScreenState extends State<KtpCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final KtpService _ktpService = KtpService();

  File? _ktpImage;
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload ID Card (KTP) ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // KTP preview or placeholder
                        if (_ktpImage != null)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_ktpImage!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _ktpImage = null);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No ID Card image selected',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Camera button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt, size: 24),
                            label: const Text(
                              'Take a Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CB04C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Gallery button
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library, size: 24),
                            label: const Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4CB04C),
                              side: const BorderSide(
                                color: Color(0xFF4CB04C),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Process button (only show when image is selected)
                        if (_ktpImage != null)
                          AppButton(
                            text: _isProcessing ? 'Processing' : 'Continue',
                            onPressed: _isProcessing ? null : _processKtp,
                            isPrimary: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CB04C),
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _processingMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Open Sans',
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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _ktpImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _ktpImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Failed to select photo: $e');
    }
  }

  Future<void> _processKtp() async {
    if (_ktpImage == null) {
      _showError('Please select an ID Card photo first');
      return;
    }

    // Validate image
    if (!_ktpService.validateKtpImage(_ktpImage!)) {
      _showError(
        'ID Card file is not valid. Ensure the file is jpg/png and under 5MB.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Uploading and processing ID Card...';
    });

    try {
      // Get user code from auth service
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        _showError('Please login again. User not authenticated.');
        setState(() => _isProcessing = false);
        return;
      }

      String userCode = currentUser['code'];

      setState(() => _processingMessage = 'Processing ID Card...');

      // Upload and extract KTP data via API
      final result = await _ktpService.uploadAndExtractKtp(
        userCode: userCode,
        ktpImageFile: _ktpImage!,
      );

      if (!mounted) return;

      // Debug log untuk melihat response dari API
      print('Upload KTP Response: $result');

      if (!result['success']) {
        setState(() => _isProcessing = false);
        _showError(result['message'] ?? 'Failed to process ID Card');
        return;
      }

      // Successfully uploaded, navigate to review screen with OCR data
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KtpReviewScreen(
              ktpImage: _ktpImage!,
              ocrData: result['data'] ?? {},
            ),
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Error: $e');
      }
    }
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
}
