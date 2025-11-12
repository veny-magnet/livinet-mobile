import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_text_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown_input.dart';
import '../../core/services/location_service.dart';
import '../../core/services/registration_service.dart';
import '../../core/services/signup_form_service.dart';
import '../../core/models/state_model.dart';
import '../../core/models/city_model.dart';
import '../../core/models/area_model.dart';
import 'ktp_capture_screen.dart';

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
  final RegistrationService _registrationService = RegistrationService();
  final SignupFormService _formService = SignupFormService();

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

  @override
  void initState() {
    super.initState();
    _restoreFormData();
    _preloadAllLocationData();
  }

  /// Restore form data from SignupFormService
  void _restoreFormData() {
    _referralCodeController.text = _formService.referralCode;
    _usernameController.text = _formService.username;
    _emailController.text = _formService.email;
    _phoneController.text = _formService.phone;
    _passwordController.text = _formService.password;
    _confirmPasswordController.text = _formService.confirmPassword;
    _addressController.text = _formService.address;
    _postcodeController.text = _formService.postcode;

    _pendingState = _formService.selectedState;
    _pendingCity = _formService.selectedCity;
    _pendingArea = _formService.selectedArea;
  }

  StateModel? _pendingState;
  CityModel? _pendingCity;
  AreaModel? _pendingArea;

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

      // Restore pending location selections after data is loaded
      if (mounted) {
        setState(() {
          if (_pendingState != null) {
            _selectedState = _states.firstWhere(
              (s) => s.id == _pendingState!.id,
              orElse: () => _pendingState!,
            );
            _currentCities = _citiesCache[_selectedState!.id] ?? [];

            if (_pendingCity != null) {
              _selectedCity = _currentCities.firstWhere(
                (c) => c.id == _pendingCity!.id,
                orElse: () => _pendingCity!,
              );
              _currentAreas = _areasCache[_selectedCity!.id] ?? [];

              if (_pendingArea != null) {
                _selectedArea = _currentAreas.firstWhere(
                  (a) => a.id == _pendingArea!.id,
                  orElse: () => _pendingArea!,
                );
              }
            }
          }
        });
      }
    } catch (e) {
      _showError('Failed to load location data: $e');
    }
  }

  void _updateCitiesForState(StateModel state) {
    setState(() {
      _selectedState = state;
      _currentCities = _citiesCache[state.id] ?? [];
      _currentAreas = [];
      _selectedCity = null;
      _selectedArea = null;
    });
    _formService.setSelectedState(state);
    _formService.setSelectedCity(null);
    _formService.setSelectedArea(null);
  }

  void _updateAreasForCity(CityModel city) async {
    setState(() {
      _selectedCity = city;
      _currentAreas = _areasCache[city.id] ?? [];
      _selectedArea = null;
    });
    _formService.setSelectedCity(city);
    _formService.setSelectedArea(null);

    if (_currentAreas.isEmpty) {
      try {
        final areas = await _locationService.getAreas(city.id);
        setState(() {
          _areasCache[city.id] = areas;
          _currentAreas = areas;
        });
      } catch (e) {
        _showError('Failed to load areas for ${city.name}');
      }
    }
  }

  /// Save current form data to service
  void _saveFormData() {
    _formService.setReferralCode(_referralCodeController.text);
    _formService.setUsername(_usernameController.text);
    _formService.setEmail(_emailController.text);
    _formService.setPhone(_phoneController.text);
    _formService.setPassword(_passwordController.text);
    _formService.setConfirmPassword(_confirmPasswordController.text);
    _formService.setAddress(_addressController.text);
    _formService.setPostcode(_postcodeController.text);
    _formService.setSelectedState(_selectedState);
    _formService.setSelectedCity(_selectedCity);
    _formService.setSelectedArea(_selectedArea);
  }

  /// Validate form and navigate to KTP capture
  void _onNext() async {
    if (!_validateForm()) return;

    // Save form data before navigating
    _saveFormData();

    // Show loading dialog for email validation
    _showLoadingDialog('Validating email...');

    try {
      // Validate email availability
      final emailValidation = await _registrationService.validateEmail(
        _emailController.text.trim(),
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!emailValidation['success']) {
        _showError(emailValidation['message'] ?? 'Unable to validate email');
        return;
      }

      if (!emailValidation['available']) {
        _showError(emailValidation['message'] ?? 'Email is already in use');
        return;
      }

      // Email is available, proceed to KTP capture
      final registrationData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'address': _addressController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'referral_code': _referralCodeController.text.trim(),
        'state_id': _selectedState!.id,
        'state_name': _selectedState!.name,
        'city_id': _selectedCity!.id,
        'city_name': _selectedCity!.name,
        'area_id': _selectedArea!.id,
        'area_name': _selectedArea!.areaName,
      };

      // Navigate to KTP capture screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                KtpCaptureScreen(registrationData: registrationData),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showError('Error validating email: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  bool _validateForm() {
    // Build registration data for validation
    final registrationData = {
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'address': _addressController.text.trim(),
      'city_id': _selectedCity?.id ?? 0,
      'state_id': _selectedState?.id ?? 0,
      'area_id': _selectedArea?.id ?? 0,
      'postcode': _postcodeController.text.trim(),
      'referral_code': _referralCodeController.text.trim(),
    };

    // Use RegistrationService to validate all fields
    final errors = _registrationService.validateRegistrationData(
      registrationData,
    );

    // Additional validations not in RegistrationService

    // Check password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      errors['password_confirm'] = 'Passwords do not match';
    }

    // Check if user agreed to terms
    if (!_agreeToTerms) {
      errors['terms'] = 'Please agree to terms and conditions';
    }

    // Check location selections
    if (_selectedState == null) {
      errors['state_id'] = 'Please select a province';
    }

    if (_selectedCity == null) {
      errors['city_id'] = 'Please select a city';
    }

    if (_selectedArea == null) {
      errors['area_id'] = 'Please select an area';
    }

    // If there are any errors, show the first one
    if (errors.isNotEmpty) {
      _showError(errors.values.first);
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

  void _showTermsAndConditionsDialog() {
    bool _hasAgreedToTerms = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Terms and Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: User Agreement
                            _buildTermsSection(
                              'User Agreement',
                              'By registering and using this service, you agree to be bound by these terms and conditions. If you do not agree to any part of these terms, you may not use our service.',
                            ),
                            const SizedBox(height: 16),

                            // Section 2: Service Usage
                            _buildTermsSection(
                              'Service Usage',
                              'You agree to use this service only for lawful purposes and in a way that does not infringe upon the rights of others or restrict their use and enjoyment of the service. You are responsible for maintaining the confidentiality of your account information and password.',
                            ),
                            const SizedBox(height: 16),

                            // Section 3: User Responsibilities
                            _buildTermsSection(
                              'User Responsibilities',
                              'You are responsible for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration. You must maintain the security of your password and immediately notify us of any unauthorized use of your account.',
                            ),
                            const SizedBox(height: 16),

                            // Section 4: Content
                            _buildTermsSection(
                              'Content and Data',
                              'You retain ownership of any content you provide. By providing content, you grant us a license to use, modify, and distribute that content. You represent and warrant that you have all rights necessary to provide such content.',
                            ),
                            const SizedBox(height: 16),

                            // Section 5: Limitation of Liability
                            _buildTermsSection(
                              'Limitation of Liability',
                              'To the fullest extent permitted by applicable law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to damages for loss of profits, goodwill, use, data, or other intangible losses.',
                            ),
                            const SizedBox(height: 16),

                            // Section 6: Termination
                            _buildTermsSection(
                              'Termination',
                              'We reserve the right to terminate or suspend your account and access to the service at any time, without notice, for conduct that we believe violates these terms or is otherwise harmful to the service, our users, or third parties.',
                            ),
                            const SizedBox(height: 16),

                            // Section 7: Changes to Terms
                            _buildTermsSection(
                              'Changes to Terms',
                              'We may modify these terms at any time. Your continued use of the service following the posting of revised terms means that you accept and agree to the changes. It is your responsibility to review these terms periodically.',
                            ),
                            const SizedBox(height: 16),

                            // Section 8: Governing Law
                            _buildTermsSection(
                              'Governing Law',
                              'These terms and conditions are governed by and construed in accordance with the laws of Indonesia, and you irrevocably submit to the exclusive jurisdiction of the courts located therein.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider
                    Divider(color: Colors.grey[300]),

                    // Checkbox and Buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _hasAgreedToTerms,
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.grey[400]!,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                onChanged: (val) {
                                  setState(
                                    () => _hasAgreedToTerms = val ?? false,
                                  );
                                },
                              ),
                              Expanded(
                                child: Text(
                                  'I understand and agree to the terms and conditions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      fontFamily: 'Open Sans',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _hasAgreedToTerms
                                      ? () {
                                          setState(() {
                                            _agreeToTerms = true;
                                          });
                                          Navigator.of(context).pop();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _hasAgreedToTerms
                                        ? Colors.green
                                        : Colors.grey[400],
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Agree',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Open Sans',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Open Sans',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            height: 1.6,
            fontFamily: 'Open Sans',
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFA5A9A9);
    final c = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          context.go('/login');
        }
      },
      child: Scaffold(
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
                                  _selectedState == null ||
                                      _currentCities.isEmpty
                                  ? (CityModel? val) {}
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
                            TextInput(
                              icon: Icons.card_giftcard,
                              hintText: "Referral Code (Optional)",
                              controller: _referralCodeController,
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
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Colors.green;
                                    }
                                    return Colors.transparent;
                                  }),
                                  onChanged: (val) {
                                    setState(
                                      () => _agreeToTerms = val ?? false,
                                    );
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTermsAndConditionsDialog,
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
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap =
                                                  _showTermsAndConditionsDialog,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: "Next",
                              onPressed: _onNext,
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
          ],
        ),
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
