import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown_input.dart';
import '../../core/widgets/app_ktp_input.dart';
import '../../core/services/location_service.dart';
import '../../core/services/ktp_service.dart';
import '../../core/services/registration_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/models/state_model.dart';
import '../../core/models/city_model.dart';
import '../../core/models/area_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _obscureConfirmPassword = true;

  // Form controllers
  final _referralCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _phoneController = TextEditingController();

  // Services
  final LocationService _locationService = LocationService();
  final KtpService _ktpService = KtpService();
  final RegistrationService _registrationService = RegistrationService();
  final AuthService _authService = AuthService();

  // Location data with caching
  List<StateModel> _states = [];
  Map<int, List<CityModel>> _citiesCache = {};
  Map<int, List<AreaModel>> _areasCache = {};

  List<CityModel> _currentCities = [];
  List<AreaModel> _currentAreas = [];

  // Selected values
  StateModel? _selectedState;
  CityModel? _selectedCity;
  AreaModel? _selectedArea;

  // KTP data
  File? _ktpImage;
  String? _ktpPath;
  Map<String, dynamic>? _ocrData;
  String? _userId;

  // UI states
  bool _isRegistering = false;
  String _loadingMessage = '';

  /// Main signup method - validates form, then processes KTP, then registers
  Future<void> _onSignup(BuildContext context) async {
    if (_isRegistering) return;

    // Step 1: Validate basic form fields first
    if (!_validateBasicForm()) return;

    setState(() {
      _isRegistering = true;
      _loadingMessage = 'Processing registration...';
    });

    try {
      // Step 2: Check if KTP image is selected
      if (_ktpImage == null) {
        _showError('Please upload your KTP image first');
        return;
      }

      // Step 3: Process KTP
      setState(() => _loadingMessage = 'Registration Process');

      // Generate user ID if not exists
      _userId ??= _registrationService.generateUserId();

      final ktpResult = await _ktpService.uploadAndProcessKtp(
        userId: _userId!,
        imageFile: _ktpImage!,
      );

      if (!ktpResult['success']) {
        _showError(ktpResult['message'] ?? 'Failed to process KTP');
        return;
      }

      // Save KTP data
      _ktpPath = ktpResult['data']['ktp_path'];
      _ocrData = ktpResult['data']['identity_card'];

      // Step 4: Proceed with registration
      setState(() => _loadingMessage = 'Creating your account...');

      // Get FCM token for push notifications
      String? fcmToken;
      try {
        fcmToken = await FcmService.getTokenForRegistration();
      } catch (e) {
        // Continue without FCM token - it's optional
      }

      // Build registration data
      final registrationData = _registrationService.buildRegistrationData(
        username: _usernameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        address: _addressController.text,
        cityId: _selectedCity!.id,
        stateId: _selectedState!.id,
        areaId: _selectedArea!.id,
        postcode: _postcodeController.text,
        referralCode: _referralCodeController.text,
        ktpPath: _ktpPath!,
        identityCard: _ocrData!,
        userId: _userId,
        fcmToken: fcmToken,
      );

      // Validate registration data
      final errors = _registrationService.validateRegistrationData(
        registrationData,
      );
      if (errors.isNotEmpty) {
        _showError(errors.values.first);
        return;
      }

      // Register user
      final result = await _registrationService.register(registrationData);

      if (result['success']) {
        setState(() => _loadingMessage = 'Sending verification email...');
        // Send email verification
        await _authService.sendEmailVerification(
          userId: registrationData['user_id'],
        );
        // Show dialog for email verification
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Check your email for verification account'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showError(result['message'] ?? 'Registration failed');
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

  /// Validate basic form fields (without KTP)
  bool _validateBasicForm() {
    if (_referralCodeController.text.isNotEmpty &&
        _referralCodeController.text.length < 3) {
      _showError('Referral code must be at least 3 characters');
      return false;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showError('Username is required');
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Email is required');
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('Phone number is required');
      return false;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Password is required');
      return false;
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      _showError('Passwords do not match');
      return false;
    }

    if (_selectedState == null) {
      _showError('Please select a province');
      return false;
    }

    if (_selectedCity == null) {
      _showError('Please select a city');
      return false;
    }

    if (_selectedArea == null) {
      _showError('Please select an area');
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      _showError('Address is required');
      return false;
    }

    if (_postcodeController.text.trim().isEmpty) {
      _showError('Postcode is required');
      return false;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to terms and conditions');
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _preloadAllLocationData();
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Preload all location data in background
  Future<void> _preloadAllLocationData() async {
    try {
      // Load states first
      _states = await _locationService.getStates();
      if (mounted) setState(() {});

      for (final state in _states) {
        try {
          final cities = await _locationService.getCities(state.id);
          _citiesCache[state.id] = cities;

          for (final city in cities) {
            try {
              final areas = await _locationService.getAreas(city.id);
              _areasCache[city.id] = areas;
            } catch (e) {
              debugPrint('Failed to preload areas for city ${city.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('Failed to preload cities for state ${state.id}: $e');
        }
      }
      debugPrint('Location data preloading completed');
    } catch (e) {
      _showError('Failed to load location data: $e');
    }
  }

  void _updateCitiesForState(StateModel state) {
    setState(() {
      _currentCities = _citiesCache[state.id] ?? [];
      _currentAreas = [];
      _selectedCity = null;
      _selectedArea = null;
    });
  }

  void _updateAreasForCity(CityModel city) async {
    setState(() {
      _currentAreas = _areasCache[city.id] ?? [];
      _selectedArea = null;
    });

    // If no cached areas, fetch from API directly
    if (_currentAreas.isEmpty) {
      try {
        final areas = await _locationService.getAreas(city.id);
        setState(() {
          _areasCache[city.id] = areas;
          _currentAreas = areas;
        });

        for (var area in areas) {}
      } catch (e) {
        _showError('Failed to load areas for ${city.name}');
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

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);
    final c = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    "Get Started!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Register your address to Livinet",
                    style: TextStyle(fontSize: 14, color: c.onSurface),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextInput(
                            icon: Icons.card_giftcard,
                            hintText: "Referral Code (Optional)",
                            controller: _referralCodeController,
                          ),
                          const SizedBox(height: 16),
                          TextInput(
                            icon: Icons.person_outline,
                            hintText: "Username",
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 16),
                          TextInput(
                            icon: Icons.email_outlined,
                            hintText: "Email",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextInput(
                            icon: Icons.phone_outlined,
                            hintText: "Phone Number",
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _passwordController,
                            hint: "Password",
                            borderColor: borderColor,
                            c: c,
                            obscure: _obscurePassword,
                            onToggle: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            hint: "Confirm Password",
                            borderColor: borderColor,
                            c: c,
                            obscure: _obscureConfirmPassword,
                            onToggle: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownInput<StateModel>(
                            icon: Icons.map_outlined,
                            hintText: "Select Province",
                            value: _selectedState,
                            items: _states
                                .map(
                                  (state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(state.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (StateModel? val) {
                              setState(() => _selectedState = val);
                              if (val != null) {
                                _updateCitiesForState(val);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownInput<CityModel>(
                            icon: Icons.location_city_outlined,
                            hintText: "Select City",
                            value: _selectedCity,
                            items: _currentCities
                                .map(
                                  (city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city.name),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                _selectedState == null || _currentCities.isEmpty
                                ? (
                                    CityModel? val,
                                  ) {} // Empty function when disabled
                                : (CityModel? val) {
                                    setState(() => _selectedCity = val);
                                    if (val != null) {
                                      _updateAreasForCity(val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),

                          DropdownInput<AreaModel>(
                            icon: Icons.my_location_outlined,
                            hintText: "Select Area",
                            value: _selectedArea,
                            items: _currentAreas
                                .map(
                                  (area) => DropdownMenuItem(
                                    value: area,
                                    child: Text(area.areaName),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                _selectedCity == null || _currentAreas.isEmpty
                                ? (AreaModel? val) {}
                                : (AreaModel? val) {
                                    setState(() => _selectedArea = val);
                                  },
                          ),
                          const SizedBox(height: 16),

                          TextInput(
                            icon: Icons.home_outlined,
                            hintText: "Address",
                            controller: _addressController,
                          ),
                          const SizedBox(height: 16),
                          TextInput(
                            icon: Icons.local_post_office_outlined,
                            hintText: "Postcode",
                            controller: _postcodeController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          KtpInput(
                            onImageSelected: (file) {
                              debugPrint("KTP Image selected: ${file?.path}");
                              setState(() {
                                _ktpImage = file;
                              });
                            },
                          ),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                fillColor: MaterialStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.green;
                                  }
                                  return Colors.transparent;
                                }),
                                onChanged: (val) {
                                  setState(() => _agreeToTerms = val ?? false);
                                },
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: "I agree to the ",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "terms and conditions",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          AppButton(
                            text: _isRegistering ? "Processing..." : "Sign Up",
                            onPressed: _isRegistering
                                ? null
                                : () => _onSignup(context),
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: c.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          debugPrint("Login tapped");
                          context.go('/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isRegistering)
            Container(
              color: Colors.black.withOpacity(0.7),
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
    required Color borderColor,
    required ColorScheme c,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline, color: borderColor),
          hintText: hint,
          hintStyle: TextStyle(color: borderColor),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: c.primary),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: borderColor,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
