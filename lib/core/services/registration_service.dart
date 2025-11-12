// lib/services/registration_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';

class RegistrationService {
  static final _config = AppConfig.instance;
  static final _logger = AppLogger.instance;
  static String get baseUrl => _config.baseUrl;
  static String get apiServer => _config.apiServer;
  static String get apiKey => _config.apiKey;

  Future<Map<String, dynamic>> registerWithKtpOcr({
    required Map<String, dynamic> registrationData,
    required File ktpImageFile,
    required Map<String, dynamic> ocrData,
  }) async {
    try {
      final fullUrl = '$baseUrl/client/registration';
      _logger.info('Registration URL: $fullUrl');
      _logger.info('Registration data: ${registrationData.keys.toList()}');
      _logger.info('OCR data: ${ocrData.keys.toList()}');

      final requestBody = {
        // Registration data
        ...registrationData,

        // KTP OCR extracted data
        'identity_card': ocrData,

        // Image metadata
        'ktp_image_base64': await _convertImageToBase64(ktpImageFile),
        'ktp_image_filename': ktpImageFile.path.split('/').last,
      };

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      if (response.statusCode == 401) {
        _logger.error(
          'Registration failed: Unauthorized (401) - Account verification required',
        );
        return {
          'success': false,
          'message':
              'Please check the email to verify your account. If you have already created an account, please contact support for assistance.',
          'data': null,
          'errors': null,
        };
      }

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _logger.info('Registration with KTP OCR successful');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        _logger.error('Registration failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'data': responseData['data'],
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      _logger.error('Registration network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
        'errors': null,
      };
    }
  }

  // Helper method to convert image to base64
  Future<String> _convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  // Build KTP OCR data structure
  Map<String, dynamic> buildKtpOcrData({
    required String nationalIdNumber,
    required String fullName,
    required String firstName,
    required String lastName,
    required String birthPlace,
    required String birthDate,
    required String gender,
    required String address,
    required String rt,
    required String rw,
    required String village,
    required String district,
    required String religion,
    required String maritalStatus,
    required String occupation,
    required String citizenship,
    required String validUntil,
    String? province,
    String? city,
  }) {
    return {
      'national_id_number': nationalIdNumber.trim(),
      'full_name': fullName.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'birth_place': birthPlace.trim(),
      'birth_date': birthDate.trim(),
      'gender': gender.trim(),
      'address': address.trim(),
      'rt': rt.trim(),
      'rw': rw.trim(),
      'village': village.trim(),
      'district': district.trim(),
      'province': province?.trim(),
      'city': city?.trim(),
      'religion': religion.trim(),
      'marital_status': maritalStatus.trim(),
      'occupation': occupation.trim(),
      'citizenship': citizenship.trim(),
      'valid_until': validUntil.trim(),
    };
  }

  // Build registration data
  Map<String, dynamic> buildRegistrationData({
    required String username,
    required String phone,
    required String email,
    required String password,
    required String address,
    required int cityId,
    required int stateId,
    required int areaId,
    required String postcode,
    String? referralCode,
    String? fcmToken,
  }) {
    return {
      'username': username.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'address': address.trim(),
      'city_id': cityId,
      'state_id': stateId,
      'area_id': areaId,
      'postcode': postcode.trim(),
      'country': 'Indonesia',
      'referral_code': referralCode?.trim(),
      'fcm_token': fcmToken,
    };
  }

  // Validate KTP image before registration
  Map<String, String> validateKtpImage(File ktpImageFile) {
    Map<String, String> errors = {};

    try {
      // Check file exists
      if (!ktpImageFile.existsSync()) {
        errors['ktp_image'] = 'KTP image file not found';
        return errors;
      }

      // Check file size (max 5MB)
      int fileSizeInBytes = ktpImageFile.lengthSync();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 5) {
        errors['ktp_image'] = 'KTP image must be less than 5MB';
        return errors;
      }

      // Check file extension
      String extension = ktpImageFile.path.toLowerCase().split('.').last;
      List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) {
        errors['ktp_image'] = 'KTP image must be JPG, JPEG, or PNG format';
        return errors;
      }
    } catch (e) {
      errors['ktp_image'] = 'Invalid KTP image file';
    }

    return errors;
  }

  // Validate registration data including KTP OCR
  Map<String, String> validateRegistrationWithKtpOcr({
    required Map<String, dynamic> data,
    required File ktpImageFile,
    required Map<String, dynamic> ocrData,
  }) {
    Map<String, String> errors = {};

    // Validate basic registration data
    errors.addAll(validateRegistrationData(data));

    // Validate KTP image
    errors.addAll(validateKtpImage(ktpImageFile));

    // Validate KTP OCR data
    errors.addAll(validateKtpOcrData(ocrData));

    return errors;
  }

  // Validate KTP OCR extracted data
  Map<String, String> validateKtpOcrData(Map<String, dynamic> ocrData) {
    Map<String, String> errors = {};

    // Required OCR fields based on BE validation
    final requiredFields = {
      'national_id_number': 'NIK is required',
      'full_name': 'Full name is required',
      'first_name': 'First name is required',
      'last_name': 'Last name is required',
      'birth_place': 'Birth place is required',
      'birth_date': 'Birth date is required',
      'gender': 'Gender is required',
      'address': 'Address is required',
      'rt': 'RT is required',
      'rw': 'RW is required',
      'village': 'Village is required',
      'district': 'District is required',
      'religion': 'Religion is required',
      'marital_status': 'Marital status is required',
      'occupation': 'Occupation is required',
      'citizenship': 'Citizenship is required',
      'valid_until': 'Valid until is required',
    };

    // Check required fields
    requiredFields.forEach((field, message) {
      if (ocrData[field] == null || ocrData[field].toString().trim().isEmpty) {
        errors[field] = message;
      }
    });

    // Validate NIK (16 digits)
    String nik = ocrData['national_id_number']?.toString().trim() ?? '';
    if (nik.isNotEmpty) {
      if (nik.length != 16 || !RegExp(r'^[0-9]{16}$').hasMatch(nik)) {
        errors['national_id_number'] = 'NIK must be exactly 16 digits';
      }
    }

    // Validate birth date format
    String birthDate = ocrData['birth_date']?.toString().trim() ?? '';
    if (birthDate.isNotEmpty) {
      // Expected format: DD-MM-YYYY or DD/MM/YYYY
      if (!RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(birthDate)) {
        errors['birth_date'] =
            'Birth date format should be DD-MM-YYYY or DD/MM/YYYY';
      }
    }

    return errors;
  }

  // Validate registration data before sending
  Map<String, String> validateRegistrationData(Map<String, dynamic> data) {
    Map<String, String> errors = {};

    // Username
    if (data['username'] == null ||
        data['username'].toString().trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (data['username'].toString().trim().length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    }

    // Phone
    String phone = data['phone']?.toString().trim() ?? '';
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (phone.length < 10 || phone.length > 15) {
      errors['phone'] = 'Phone number must be between 10-15 digits';
    } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      errors['phone'] = 'Phone number must contain only digits';
    }

    // Email
    String email = data['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Password
    String password = data['password']?.toString() ?? '';
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 8 || password.length > 20) {
      errors['password'] = 'Password must be between 8-20 characters';
    }

    // Address
    if (data['address'] == null ||
        data['address'].toString().trim().length < 5) {
      errors['address'] = 'Address must be at least 5 characters';
    }

    // Location IDs
    if (data['city_id'] == null || data['city_id'] == 0) {
      errors['city_id'] = 'Please select a city';
    }
    if (data['state_id'] == null || data['state_id'] == 0) {
      errors['state_id'] = 'Please select a state/province';
    }
    if (data['area_id'] == null || data['area_id'] == 0) {
      errors['area_id'] = 'Please select an area';
    }

    // Postcode
    String postcode = data['postcode']?.toString().trim() ?? '';
    if (postcode.isEmpty) {
      errors['postcode'] = 'Postcode is required';
    } else if (postcode.length < 3) {
      errors['postcode'] = 'Postcode must be at least 3 digits';
    }

    // Note: Identity card data validation removed - KTP will be uploaded separately after registration

    return errors;
  }

  // Check if phone number exists
  Future<Map<String, dynamic>> checkPhoneExists(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check/phone'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': phone}),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      return {
        'exists': responseData['exists'] ?? false,
        'message': responseData['message'] ?? 'Phone check completed',
      };
    } catch (e) {
      return {'exists': false, 'message': 'Unable to check phone number'};
    }
  }

  // Check if email exists
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check/email'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      return {
        'exists': responseData['exists'] ?? false,
        'message': responseData['message'] ?? 'Email check completed',
      };
    } catch (e) {
      return {'exists': false, 'message': 'Unable to check email address'};
    }
  }

  // Validate email availability before registration
  Future<Map<String, dynamic>> validateEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate/email'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseData['data'] ?? {};
        return {
          'success': true,
          'available': data['available'] ?? false,
          'message':
              data['message'] ??
              responseData['message'] ??
              'Email validation completed',
        };
      } else {
        return {
          'success': false,
          'available': false,
          'message': responseData['message'] ?? 'Unable to validate email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'available': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
