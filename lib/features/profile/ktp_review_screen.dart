import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_dropdown_input.dart';
import '../../core/services/ktp_service.dart';
import '../../core/services/auth_service.dart';

class KtpReviewScreen extends StatefulWidget {
  final File? ktpImage;
  final Map<String, dynamic> ocrData;
  final bool isPreviewMode;

  const KtpReviewScreen({
    super.key,
    this.ktpImage,
    required this.ocrData,
    this.isPreviewMode = false,
  });

  @override
  State<KtpReviewScreen> createState() => _KtpReviewScreenState();
}

class _KtpReviewScreenState extends State<KtpReviewScreen> {
  // Services
  final KtpService _ktpService = KtpService();
  final AuthService _authService = AuthService();

  // Text Controllers
  late TextEditingController _nikController;
  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kecamatanController;
  late TextEditingController _kotaController;
  late TextEditingController _provinsiController;
  late TextEditingController _citizenshipController;
  late TextEditingController _berlakuHinggaController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedAgama;
  String? _selectedStatusPerkawinan;
  String? _selectedPekerjaan;

  // State
  bool _isSubmitting = false;
  final List<String> _genderOptions = ['LAKI-LAKI', 'PEREMPUAN'];
  final List<String> _agamaOptions = [
    'ISLAM',
    'KRISTEN',
    'KATOLIK',
    'HINDU',
    'BUDDHA',
    'KONGHUCU',
  ];
  final List<String> _statusPerkawinanOptions = [
    'BELUM KAWIN',
    'KAWIN',
    'CERAI HIDUP',
    'CERAI MATI',
  ];
  final List<String> _pekerjaanOptions = [
    'BELUM/TIDAK BEKERJA',
    'PELAJAR/MAHASISWA',
    'PEGAWAI NEGERI SIPIL',
    'PEGAWAI SWASTA',
    'WIRASWASTA',
    'PETANI',
    'NELAYAN',
    'GURU',
    'DOKTER',
    'TENTARA NASIONAL INDONESIA',
    'KEPOLISIAN RI',
    'PENSIUNAN',
    'LAINNYA',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Debug log untuk melihat data yang diterima
    print('OCR Data received: ${widget.ocrData}');

    _nikController = TextEditingController(
      text: widget.ocrData['national_id_number'] ?? widget.ocrData['nik'] ?? '',
    );
    _namaController = TextEditingController(
      text: widget.ocrData['full_name'] ?? widget.ocrData['nama'] ?? '',
    );
    _tempatLahirController = TextEditingController(
      text:
          widget.ocrData['birth_place'] ?? widget.ocrData['tempat_lahir'] ?? '',
    );
    _tanggalLahirController = TextEditingController(
      text:
          widget.ocrData['birth_date'] ?? widget.ocrData['tanggal_lahir'] ?? '',
    );
    _alamatController = TextEditingController(
      text: widget.ocrData['address'] ?? widget.ocrData['alamat'] ?? '',
    );
    _rtController = TextEditingController(text: widget.ocrData['rt'] ?? '');
    _rwController = TextEditingController(text: widget.ocrData['rw'] ?? '');
    _kelurahanController = TextEditingController(
      text: widget.ocrData['village'] ?? widget.ocrData['kelurahan'] ?? '',
    );
    _kecamatanController = TextEditingController(
      text: widget.ocrData['sub_district'] ?? widget.ocrData['kecamatan'] ?? '',
    );
    _kotaController = TextEditingController(
      text:
          widget.ocrData['district'] ??
          widget.ocrData['kabupaten'] ??
          widget.ocrData['city'] ??
          '',
    );
    _provinsiController = TextEditingController(
      text: widget.ocrData['province'] ?? widget.ocrData['provinsi'] ?? '',
    );
    _citizenshipController = TextEditingController(
      text: widget.ocrData['citizenship'] ?? 'WNI',
    );
    _berlakuHinggaController = TextEditingController(
      text:
          widget.ocrData['valid_until'] ??
          widget.ocrData['berlaku_hingga'] ??
          '',
    );

    // Initialize dropdown values - normalize gender from API
    String? gender =
        widget.ocrData['gender'] ?? widget.ocrData['jenis_kelamin'];
    if (gender != null) {
      gender = gender.toUpperCase();
      if (gender.contains('LAKI')) {
        _selectedGender = 'LAKI-LAKI';
      } else if (gender.contains('PEREMPUAN')) {
        _selectedGender = 'PEREMPUAN';
      }
    }

    final agama = widget.ocrData['religion'] ?? widget.ocrData['agama'];
    _selectedAgama = _agamaOptions.contains(agama) ? agama : null;

    final status =
        widget.ocrData['marital_status'] ?? widget.ocrData['status_perkawinan'];
    _selectedStatusPerkawinan = _statusPerkawinanOptions.contains(status)
        ? status
        : null;

    final pekerjaan =
        widget.ocrData['occupation'] ?? widget.ocrData['pekerjaan'];
    _selectedPekerjaan = _pekerjaanOptions.contains(pekerjaan)
        ? pekerjaan
        : null;
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kotaController.dispose();
    _provinsiController.dispose();
    _citizenshipController.dispose();
    _berlakuHinggaController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;

    if (!_validateKtpData()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Uploading ID Card Data...'),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      // Get user code from auth
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || currentUser['code'] == null) {
        if (mounted) Navigator.of(context).pop();
        _showError('User code not found. Please login again.');
        return;
      }

      final userCode = currentUser['code'] as String;

      final ktpDataToSync = {
        'nik': _nikController.text.trim(),
        'nama': _namaController.text.trim(),
        'tempat_lahir': _tempatLahirController.text.trim(),
        'tanggal_lahir': _tanggalLahirController.text.trim(),
        'jenis_kelamin': _selectedGender ?? '',
        'alamat': _alamatController.text.trim(),
        'rt': _rtController.text.trim(),
        'rw': _rwController.text.trim(),
        'kelurahan': _kelurahanController.text.trim(),
        'kecamatan': _kecamatanController.text.trim(),
        'city': _kotaController.text.trim(),
        'provinsi': _provinsiController.text.trim(),
        'agama': _selectedAgama ?? '',
        'status_perkawinan': _selectedStatusPerkawinan ?? '',
        'pekerjaan': _selectedPekerjaan ?? '',
        'citizenship': _citizenshipController.text.trim(),
        'valid_until': _berlakuHinggaController.text.trim(),
      };

      print('KTP Data to Sync: $ktpDataToSync');

      // Call sync API
      final result = await _ktpService.syncKtpData(
        userCode: userCode,
        ktpData: ktpDataToSync,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result['success']) {
          _showSuccess(result['message'] ?? 'KTP data saved successfully');
          // Navigate to profile_screen after success
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/profile');
            }
          });
        } else {
          _showError(result['message'] ?? 'Failed to save KTP data');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateKtpData() {
    if (_nikController.text.trim().isEmpty) {
      _showError('ID Number cannot be empty');
      return false;
    }

    if (_nikController.text.trim().length != 16) {
      _showError('ID Number must be 16 digits');
      return false;
    }

    if (_namaController.text.trim().isEmpty) {
      _showError('Full Name cannot be empty');
      return false;
    }

    if (_tempatLahirController.text.trim().isEmpty) {
      _showError('Place of Birth cannot be empty');
      return false;
    }

    if (_tanggalLahirController.text.trim().isEmpty) {
      _showError('Date of Birth cannot be empty');
      return false;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _showError('Gender must be selected');
      return false;
    }

    if (_alamatController.text.trim().isEmpty) {
      _showError('Address cannot be empty');
      return false;
    }

    if (_kotaController.text.trim().isEmpty) {
      _showError('City/Regency cannot be empty');
      return false;
    }

    if (_provinsiController.text.trim().isEmpty) {
      _showError('Province cannot be empty');
      return false;
    }

    if (_selectedAgama == null || _selectedAgama!.isEmpty) {
      _showError('Religion must be selected');
      return false;
    }

    if (_berlakuHinggaController.text.trim().isEmpty) {
      _showError('Valid Until cannot be empty');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header - sama persis seperti edit_profile_screen
          if (widget.isPreviewMode)
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
                            // Blur Container with KTP Info
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
                                        // Full Name
                                        Text(
                                          _namaController.text,
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
                                        // NIK
                                        Text(
                                          _nikController.text,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            fontFamily: 'Open Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Profile Picture Circle (Badge Icon)
                            Positioned(
                              top: 38,
                              left: (screenWidth - 105) / 2,
                              child: Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CB04C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.badge,
                                    size: 50,
                                    color: Colors.white,
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
            )
          else
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 40,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              titleSpacing: 0,
              title: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Review ID Card',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KTP Image preview - only show in upload mode
                  if (!widget.isPreviewMode && widget.ktpImage != null) ...[
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(widget.ktpImage!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextInput(
                    icon: Icons.badge,
                    hintText: 'ID Number',
                    controller: _nikController,
                    keyboardType: TextInputType.number,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.person,
                    hintText: 'Full Name',
                    controller: _namaController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.location_on,
                    hintText: 'Place of Birth',
                    controller: _tempatLahirController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.calendar_today,
                    hintText: 'Date of Birth (DD-MM-YYYY)',
                    controller: _tanggalLahirController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isPreviewMode)
                    DropdownInput<String>(
                      value: _selectedGender,
                      icon: Icons.wc,
                      hintText: 'Select Gender',
                      items: _genderOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    )
                  else
                    TextInput(
                      icon: Icons.wc,
                      hintText: 'Gender',
                      controller: TextEditingController(
                        text: _selectedGender ?? '',
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.home,
                    hintText: 'Address',
                    controller: _alamatController,
                    maxLines: 2,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextInput(
                          icon: Icons.house,
                          hintText: 'RT',
                          controller: _rtController,
                          keyboardType: TextInputType.number,
                          enabled: !widget.isPreviewMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextInput(
                          icon: Icons.house,
                          hintText: 'RW',
                          controller: _rwController,
                          keyboardType: TextInputType.number,
                          enabled: !widget.isPreviewMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.location_city,
                    hintText: 'Village/Sub-district',
                    controller: _kelurahanController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.map,
                    hintText: 'Sub-district',
                    controller: _kecamatanController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.location_city,
                    hintText: 'City/Regency',
                    controller: _kotaController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.map_outlined,
                    hintText: 'Province',
                    controller: _provinsiController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isPreviewMode)
                    DropdownInput<String>(
                      value: _selectedAgama,
                      icon: Icons.church,
                      hintText: 'Select Religion',
                      items: _agamaOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAgama = value),
                    )
                  else
                    TextInput(
                      icon: Icons.church,
                      hintText: 'Religion',
                      controller: TextEditingController(
                        text: _selectedAgama ?? '',
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 16),
                  if (!widget.isPreviewMode)
                    DropdownInput<String>(
                      value: _selectedStatusPerkawinan,
                      icon: Icons.favorite,
                      hintText: 'Select Marital Status',
                      items: _statusPerkawinanOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedStatusPerkawinan = value),
                    )
                  else
                    TextInput(
                      icon: Icons.favorite,
                      hintText: 'Marital Status',
                      controller: TextEditingController(
                        text: _selectedStatusPerkawinan ?? '',
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 16),
                  if (!widget.isPreviewMode)
                    DropdownInput<String>(
                      value: _selectedPekerjaan,
                      icon: Icons.work,
                      hintText: 'Select Occupation',
                      items: _pekerjaanOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPekerjaan = value),
                    )
                  else
                    TextInput(
                      icon: Icons.work,
                      hintText: 'Occupation',
                      controller: TextEditingController(
                        text: _selectedPekerjaan ?? '',
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.public,
                    hintText: 'Citizenship',
                    controller: _citizenshipController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 16),
                  TextInput(
                    icon: Icons.event,
                    hintText: 'Valid Until',
                    controller: _berlakuHinggaController,
                    enabled: !widget.isPreviewMode,
                  ),
                  const SizedBox(height: 32),
                  // Only show Save button in edit mode (not preview mode)
                  if (!widget.isPreviewMode)
                    AppButton(
                      text: _isSubmitting ? 'Saving...' : 'Save Data',
                      onPressed: _isSubmitting ? null : _onSubmit,
                      isPrimary: true,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
