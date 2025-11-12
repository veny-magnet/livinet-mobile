import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/openai_ocr_service.dart';
import 'ktp_review_screen.dart';

class KtpCaptureScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const KtpCaptureScreen({super.key, required this.registrationData});

  @override
  State<KtpCaptureScreen> createState() => _KtpCaptureScreenState();
}

class _KtpCaptureScreenState extends State<KtpCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _ktpImage;
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradients
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
                        icon: const Icon(Icons.arrow_back, color: Colors.green),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload KTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Step 2 of 3',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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

                        // Instructions card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tips for a good KTP photo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem('Ensure KTP is well-lit'),
                              _buildTipItem(
                                'Avoid shadows and light reflections',
                              ),
                              _buildTipItem('Take a clear, non-blurry photo'),
                              _buildTipItem('Ensure the entire KTP is visible'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

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
                                  'No KTP photo yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
                              'Take KTP Photo',
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
                              'Pick from Gallery',
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
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _processKtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Process KTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _processingMessage,
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

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
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
      _showError('Please select a KTP photo first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Scanning KTP...';
    });

    try {
      // Process KTP with OCR
      final ocrData = await _processKtpWithOcr(_ktpImage!);

      if (!mounted) return;

      if (ocrData == null) {
        setState(() {
          _isProcessing = false;
          _processingMessage = '';
        });
        _showError(
          'Failed to scan KTP. Ensure the photo is clear and try again.',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KtpReviewScreen(
            registrationData: widget.registrationData,
            ktpImage: _ktpImage!,
            ocrData: ocrData,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingMessage = '';
        });
        _showError('Error: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _processKtpWithOcr(File ktpImageFile) async {
    try {
      debugPrint('Scanning KTP');

      setState(() {
        _isProcessing = true;
        _processingMessage = 'Scanning KTP';
      });

      // Call OpenAI OCR Service
      final extractedData = await OpenAIOcrService.extractKtpData(ktpImageFile);

      if (extractedData == null) {
        throw Exception('Failed to extract KTP data from OpenAI');
      }

      // Validate extracted KTP data
      if (!OpenAIOcrService.validateKtpData(extractedData)) {
        throw Exception(
          'Image does not appear to be a valid KTP. Please upload a clear KTP photo.',
        );
      }

      debugPrint('OpenAI OCR Result: $extractedData');

      setState(() {
        _processingMessage = 'Processing OCR result...';
      });

      // Build final result with proper structure
      final firstName =
          extractedData['nama']?.toString().split(' ').first ?? '';
      final lastName = extractedData['nama'] != null
          ? extractedData['nama']!.toString().split(' ').skip(1).join(' ')
          : '';

      return {
        'national_id_number': extractedData['nik'] ?? '',
        'full_name': extractedData['nama'] ?? '',
        'first_name': firstName,
        'last_name': lastName,
        'birth_place': extractedData['tempat_lahir'] ?? '',
        'birth_date': extractedData['tanggal_lahir'] ?? '',
        'gender': extractedData['jenis_kelamin'] ?? '',
        'address': extractedData['alamat'] ?? '',
        'rt': extractedData['rt'] ?? '',
        'rw': extractedData['rw'] ?? '',
        'village': extractedData['kelurahan'] ?? '',
        'district': extractedData['kecamatan'] ?? '',
        'religion': extractedData['agama'] ?? '',
        'marital_status': extractedData['status_perkawinan'] ?? '',
        'occupation': extractedData['pekerjaan'] ?? '',
        'citizenship': extractedData['kewarganegaraan'] ?? 'WNI',
        'valid_until': extractedData['berlaku_hingga'] ?? '',
        'province': extractedData['provinsi'] ?? '',
        'city': extractedData['kota'] ?? '',
      };
    } catch (e) {
      debugPrint('OpenAI OCR processing error: $e');
      _showError('Error scanning KTP: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
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
