import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/registration_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/signup_form_service.dart';
import 'ktp_capture_screen.dart';

class KtpReviewScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  final File ktpImage;
  final Map<String, dynamic> ocrData;

  const KtpReviewScreen({
    super.key,
    required this.registrationData,
    required this.ktpImage,
    required this.ocrData,
  });

  @override
  State<KtpReviewScreen> createState() => _KtpReviewScreenState();
}

class _KtpReviewScreenState extends State<KtpReviewScreen> {
  final RegistrationService _registrationService = RegistrationService();
  final AuthService _authService = AuthService();

  // Controllers for editable fields
  late TextEditingController _nikController;
  late TextEditingController _fullNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _villageController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _validUntilController;

  String? _selectedGender;
  String? _selectedReligion;
  String? _selectedMaritalStatus;
  String? _selectedOccupation;
  String? _selectedCitizenship;

  bool _isRegistering = false;
  String _loadingMessage = '';

  final List<String> _genderOptions = ['LAKI-LAKI', 'PEREMPUAN'];
  final List<String> _religionOptions = [
    'ISLAM',
    'KRISTEN',
    'KATOLIK',
    'HINDU',
    'BUDDHA',
    'KONGHUCU',
  ];
  final List<String> _maritalStatusOptions = [
    'BELUM KAWIN',
    'KAWIN',
    'CERAI HIDUP',
    'CERAI MATI',
  ];
  final List<String> _occupationOptions = [
    'BELUM/TIDAK BEKERJA',
    'PELAJAR/MAHASISWA',
    'MENGURUS RUMAH TANGGA',
    'WIRASWASTA',
    'KARYAWAN SWASTA',
    'PNS',
    'TNI/POLRI',
    'PENSIUNAN',
    'LAINNYA',
  ];
  final List<String> _citizenshipOptions = ['WNI', 'WNA'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nikController = TextEditingController(
      text: widget.ocrData['national_id_number'] ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.ocrData['full_name'] ?? '',
    );
    _firstNameController = TextEditingController(
      text: widget.ocrData['first_name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.ocrData['last_name'] ?? '',
    );
    _birthPlaceController = TextEditingController(
      text: widget.ocrData['birth_place'] ?? '',
    );
    _birthDateController = TextEditingController(
      text: widget.ocrData['birth_date'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.ocrData['address'] ?? '',
    );
    _rtController = TextEditingController(text: widget.ocrData['rt'] ?? '');
    _rwController = TextEditingController(text: widget.ocrData['rw'] ?? '');
    _villageController = TextEditingController(
      text: widget.ocrData['village'] ?? '',
    );
    _districtController = TextEditingController(
      text: widget.ocrData['district'] ?? '',
    );
    _provinceController = TextEditingController(
      text: widget.ocrData['province'] ?? '',
    );
    _cityController = TextEditingController(text: widget.ocrData['city'] ?? '');
    _validUntilController = TextEditingController(
      text: widget.ocrData['valid_until'] ?? '',
    );

    _selectedGender = _genderOptions.contains(widget.ocrData['gender'])
        ? widget.ocrData['gender']
        : null;

    _selectedReligion = _religionOptions.contains(widget.ocrData['religion'])
        ? widget.ocrData['religion']
        : null;

    _selectedMaritalStatus =
        _maritalStatusOptions.contains(widget.ocrData['marital_status'])
        ? widget.ocrData['marital_status']
        : null;

    _selectedOccupation =
        _occupationOptions.contains(widget.ocrData['occupation'])
        ? widget.ocrData['occupation']
        : null;

    _selectedCitizenship =
        _citizenshipOptions.contains(widget.ocrData['citizenship'])
        ? widget.ocrData['citizenship']
        : null;
  }

  @override
  void dispose() {
    _nikController.dispose();
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isRegistering) return;

    if (!_validateKtpData()) return;

    setState(() {
      _isRegistering = true;
      _loadingMessage = 'Menyiapkan registrasi...';
    });

    try {
      // Get FCM token
      setState(() => _loadingMessage = 'Setting up notifications');

      String fcmToken;
      try {
        fcmToken = await FcmService.getTokenForRegistration();
      } catch (e) {
        setState(() => _loadingMessage = '');
        _showError(
          'Notification Setup Required: We need notification permissions to complete your registration. Please allow notifications and try again.\n\nError: ${e.toString()}',
        );
        return;
      }

      // Build final registration data
      setState(() => _loadingMessage = 'Creating your account');

      final registrationData = _registrationService.buildRegistrationData(
        username: widget.registrationData['username'],
        phone: widget.registrationData['phone'],
        email: widget.registrationData['email'],
        password: widget.registrationData['password'],
        address: widget.registrationData['address'],
        cityId: widget.registrationData['city_id'],
        stateId: widget.registrationData['state_id'],
        areaId: widget.registrationData['area_id'],
        postcode: widget.registrationData['postcode'],
        referralCode: widget.registrationData['referral_code'],
        fcmToken: fcmToken,
      );

      // Build KTP OCR data from edited fields
      final ktpOcrData = _registrationService.buildKtpOcrData(
        nationalIdNumber: _nikController.text.trim(),
        fullName: _fullNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthPlace: _birthPlaceController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _selectedGender ?? '',
        address: _addressController.text.trim(),
        rt: _rtController.text.trim(),
        rw: _rwController.text.trim(),
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        religion: _selectedReligion ?? '',
        maritalStatus: _selectedMaritalStatus ?? '',
        occupation: _selectedOccupation ?? '',
        citizenship: _selectedCitizenship ?? '',
        validUntil: _validUntilController.text.trim(),
        province: _provinceController.text.trim(),
        city: _cityController.text.trim(),
      );

      // Validate registration data
      final errors = _registrationService.validateRegistrationWithKtpOcr(
        data: registrationData,
        ktpImageFile: widget.ktpImage,
        ocrData: ktpOcrData,
      );

      if (errors.isNotEmpty) {
        _showError(errors.values.first);
        return;
      }

      // Register user
      final result = await _registrationService.registerWithKtpOcr(
        registrationData: registrationData,
        ktpImageFile: widget.ktpImage,
        ocrData: ktpOcrData,
      );

      if (!result['success']) {
        _showError(result['message'] ?? 'Registration failed');

        // Check if it's a 401 Unauthorized error
        if (result['message'] != null &&
            result['message'].contains('Please verify your account')) {
          // Show a more prominent dialog for account verification issues
          _showAccountVerificationDialog(result['message']);
        }
        return;
      }

      // Send email verification
      setState(() => _loadingMessage = 'Finalizing registration');
      final userId = result['data']['user_code'];
      await _authService.sendEmailVerification(userId: userId);

      // Clear saved form data after successful registration
      SignupFormService().clearFormData();

      // Show success dialog
      if (mounted) {
        _showEmailVerificationDialog();
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isRegistering = false;
        _loadingMessage = '';
      });
    }
  }

  bool _validateKtpData() {
    if (_nikController.text.trim().isEmpty) {
      _showError('NIK cannot be empty');
      return false;
    }

    if (_nikController.text.trim().length != 16) {
      _showError('NIK must be 16 digits');
      return false;
    }

    if (_fullNameController.text.trim().isEmpty) {
      _showError('Full name cannot be empty');
      return false;
    }

    if (_birthPlaceController.text.trim().isEmpty) {
      _showError('Place of birth cannot be empty');
      return false;
    }

    if (_birthDateController.text.trim().isEmpty) {
      _showError('Date of birth cannot be empty');
      return false;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _showError('Gender must be selected');
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      _showError('Address cannot be empty');
      return false;
    }

    return true;
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

  void _showAccountVerificationDialog(String message) {
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
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Account Verification Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Go back to signup screen
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Go Back to Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontFamily: 'Open Sans',
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
                    'Registration Successful!',
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
                    'Please check your email to verify your account.',
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
                    widget.registrationData['email'],
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
                        Navigator.of(context).pop();
                        context.go('/login');
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
                        'Go to Login',
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
                        onPressed: () {
                          // Go back to KTP capture screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KtpCaptureScreen(
                                registrationData: widget.registrationData,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Data KTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Step 3 of 3 - Review & Edit if necessary',
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
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KTP Image preview
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              widget.ktpImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Personal Info Section
                        _buildSectionTitle('Personal Data'),
                        _buildTextField(
                          controller: _nikController,
                          label: 'NIK',
                          icon: Icons.badge,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _birthPlaceController,
                          label: 'Place of Birth',
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _birthDateController,
                          label: 'Date of Birth (DD-MM-YYYY)',
                          icon: Icons.calendar_today,
                          hint: 'Example: 01-01-1990',
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedGender,
                          label: 'Gender',
                          icon: Icons.wc,
                          items: _genderOptions,
                          onChanged: (val) =>
                              setState(() => _selectedGender = val),
                        ),

                        const SizedBox(height: 24),

                        // Address Section
                        _buildSectionTitle('Address'),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.home,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _rtController,
                                label: 'RT',
                                icon: Icons.house,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _rwController,
                                label: 'RW',
                                icon: Icons.house,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _villageController,
                          label: 'Kelurahan/Desa',
                          icon: Icons.location_city,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _districtController,
                          label: 'Kecamatan',
                          icon: Icons.map,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _cityController,
                          label: 'Kota/Kabupaten',
                          icon: Icons.location_city,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _provinceController,
                          label: 'Provinsi',
                          icon: Icons.map_outlined,
                        ),

                        const SizedBox(height: 24),

                        // Additional Info Section
                        _buildDropdown(
                          value: _selectedReligion,
                          label: 'Religion',
                          icon: Icons.church,
                          items: _religionOptions,
                          onChanged: (val) =>
                              setState(() => _selectedReligion = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedMaritalStatus,
                          label: 'Marital Status',
                          icon: Icons.favorite,
                          items: _maritalStatusOptions,
                          onChanged: (val) =>
                              setState(() => _selectedMaritalStatus = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedOccupation,
                          label: 'Occupation',
                          icon: Icons.work,
                          items: _occupationOptions,
                          onChanged: (val) =>
                              setState(() => _selectedOccupation = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedCitizenship,
                          label: 'Kewarganegaraan',
                          icon: Icons.flag,
                          items: _citizenshipOptions,
                          onChanged: (val) =>
                              setState(() => _selectedCitizenship = val),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _validUntilController,
                          label: 'Valid Until',
                          icon: Icons.event,
                          hint: '',
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isRegistering ? null : _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CB04C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isRegistering)
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    String? hint,
  }) {
    final isEmpty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isEmpty) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.orange[700],
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
            hintText: hint ?? label,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isEmpty ? Colors.orange : Colors.grey[300]!,
                width: isEmpty ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isEmpty ? Colors.orange : Colors.grey[300]!,
                width: isEmpty ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: isEmpty ? Colors.orange.withOpacity(0.05) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isEmpty = value == null || value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isEmpty) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.orange[700],
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isEmpty ? Colors.orange.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEmpty ? Colors.orange : Colors.grey[300]!,
              width: isEmpty ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            hint: Text(
              'Select $label',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            dropdownColor: Colors.white,
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
