import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import 'app_logger.dart';
import 'auth_service.dart';

class KtpService {
  static final _config = AppConfig.instance;
  static final _logger = AppLogger.instance;
  static final _authService = AuthService();
  static String get baseUrl => _config.baseUrl;
  static String get apiKey => _config.apiKey;

  /// Get KTP data for a user
  Future<Map<String, dynamic>> getKtpData({required String userCode}) async {
    try {
      String? bearerToken = await _authService.getAuthToken();

      if (bearerToken == null || bearerToken.isEmpty) {
        _logger.error('Bearer token not found. Please login again.');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/get/ktp',
        ).replace(queryParameters: {'code': userCode}),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      _logger.info('Get KTP Response Status: ${response.statusCode}');
      _logger.info('Get KTP Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _logger.info('KTP data fetched successfully');

        // Extract KTP data from API response
        final ktpData = responseData['data'] ?? {};
        return {
          'success': true,
          'data': {
            'user_id': ktpData['user_id'] ?? '',
            'national_id_number': ktpData['national_id_number'] ?? '',
            'full_name': ktpData['full_name'] ?? '',
            'first_name': ktpData['first_name'] ?? '',
            'last_name': ktpData['last_name'] ?? '',
            'birth_place': ktpData['birth_place'] ?? '',
            'birth_date': ktpData['birth_date'] ?? '',
            'gender': ktpData['gender'] ?? '',
            'address': ktpData['address'] ?? '',
            'rt': ktpData['rt'] ?? '',
            'rw': ktpData['rw'] ?? '',
            'village': ktpData['village'] ?? '',
            'sub_district': ktpData['sub_district'] ?? '',
            'district': ktpData['district'] ?? '',
            'province': ktpData['province'] ?? '',
            'religion': ktpData['religion'] ?? '',
            'marital_status': ktpData['marital_status'] ?? '',
            'occupation': ktpData['occupation'] ?? '',
            'created_at': ktpData['created_at'] ?? '',
            'updated_at': ktpData['updated_at'] ?? '',
          },
          'message':
              responseData['message'] ?? 'KTP data retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        _logger.error('Authentication failed: Unauthorized (401)');
        return {
          'success': false,
          'message': 'Your session has expired. Please login again.',
          'data': null,
        };
      } else if (response.statusCode == 404) {
        _logger.warning('KTP data not found for user code: $userCode');
        return {
          'success': false,
          'message': 'KTP data not found. Please upload your KTP first.',
          'data': null,
        };
      } else {
        _logger.error('Fetch KTP failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch KTP data',
          'data': null,
        };
      }
    } catch (e) {
      _logger.error('Get KTP network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Upload and extract KTP
  Future<Map<String, dynamic>> uploadAndExtractKtp({
    required String userCode,
    required File ktpImageFile,
  }) async {
    try {
      String? bearerToken = await _authService.getAuthToken();

      if (bearerToken == null || bearerToken.isEmpty) {
        _logger.error('Bearer token not found. Please login again.');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/ktp'),
      );

      // Add required headers
      request.headers.addAll({
        'Authorization': 'Bearer $bearerToken',
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });

      request.fields['code'] = userCode;

      // Add KTP image file
      String fileName = ktpImageFile.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'ktp_image',
          ktpImageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      _logger.info('Uploading KTP to: $baseUrl/upload/ktp');
      _logger.info('User Code: $userCode');
      _logger.info('Bearer Token: ${bearerToken.substring(0, 20)}...');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _logger.info('KTP Upload Response Status: ${response.statusCode}');
      _logger.info('KTP Upload Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _logger.info('KTP extraction successful');

        // Extract KTP data from API response
        // Handle nested data structure from backend
        final apiData = responseData['data'] ?? {};
        final ktpData =
            apiData['data'] ??
            apiData; // Try nested 'data' first, fallback to apiData

        return {
          'success': true,
          'data': {
            'nik': ktpData['nik'] ?? '',
            'nama': ktpData['nama'] ?? '',
            'tempat_lahir': ktpData['tempat_lahir'] ?? '',
            'tanggal_lahir': ktpData['tanggal_lahir'] ?? '',
            'jenis_kelamin': ktpData['jenis_kelamin'] ?? '',
            'alamat': ktpData['alamat'] ?? '',
            'rt': ktpData['rt'] ?? '',
            'rw': ktpData['rw'] ?? '',
            'kelurahan': ktpData['kelurahan'] ?? '',
            'kecamatan': ktpData['kecamatan'] ?? '',
            'kabupaten': ktpData['kabupaten'] ?? ktpData['kota'] ?? '',
            'provinsi': ktpData['provinsi'] ?? '',
            'agama': ktpData['agama'] ?? '',
            'status_perkawinan': ktpData['status_perkawinan'] ?? '',
            'pekerjaan': ktpData['pekerjaan'] ?? '',
            'berlaku_hingga': ktpData['berlaku_hingga'] ?? '',
          },
          'validated':
              apiData['validated'] ?? responseData['validated'] ?? false,
          'extraction_timestamp':
              apiData['extraction_timestamp'] ??
              responseData['extraction_timestamp'],
          'message': responseData['message'] ?? 'KTP processed successfully',
        };
      } else if (response.statusCode == 401) {
        _logger.error('Authentication failed: Unauthorized (401)');
        return {
          'success': false,
          'message': 'Your session has expired. Please login again.',
          'data': null,
        };
      } else {
        _logger.error('KTP extraction failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'KTP processing failed',
          'data': null,
        };
      }
    } catch (e) {
      _logger.error('KTP upload network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Validate KTP image before upload
  bool validateKtpImage(File imageFile) {
    try {
      // Check file exists
      if (!imageFile.existsSync()) {
        _logger.warning('KTP file does not exist');
        return false;
      }

      // Check file size (max 5MB = 5120 KB)
      int fileSizeInBytes = imageFile.lengthSync();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 5) {
        _logger.warning(
          'KTP file too large: ${fileSizeInMB.toStringAsFixed(2)}MB (max 5MB)',
        );
        return false;
      }

      // Check file extension
      String extension = imageFile.path.toLowerCase().split('.').last;
      List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) {
        _logger.warning(
          'Invalid KTP file format: $extension (allowed: jpg, jpeg, png)',
        );
        return false;
      }

      _logger.info('KTP image validation passed');
      return true;
    } catch (e) {
      _logger.error('KTP image validation error: $e');
      return false;
    }
  }

  /// Get supported image formats
  List<String> getSupportedFormats() {
    return ['jpg', 'jpeg', 'png'];
  }

  /// Get max file size in MB
  double getMaxFileSizeMB() {
    return 5.0;
  }

  /// Sync KTP data to WHMCS
  Future<Map<String, dynamic>> syncKtpData({
    required String userCode,
    required Map<String, dynamic> ktpData,
  }) async {
    try {
      String? bearerToken = await _authService.getAuthToken();

      if (bearerToken == null || bearerToken.isEmpty) {
        _logger.error('Bearer token not found. Please login again.');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final requestBody = {'code': userCode, 'ktp_data': ktpData};

      _logger.info('Syncing KTP to: $baseUrl/sync/ktp');
      _logger.info('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/sync/ktp'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logger.info('KTP Sync Response Status: ${response.statusCode}');
      _logger.info('KTP Sync Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _logger.info('KTP sync successful');
        return {
          'success': true,
          'user_id': responseData['user_id'] ?? '',
          'identity_card_code': responseData['identity_card_code'] ?? '',
          'message': responseData['message'] ?? 'KTP synced successfully',
          'whmcs_response': responseData['whmcs_response'],
        };
      } else if (response.statusCode == 401) {
        _logger.error('Authentication failed: Unauthorized (401)');
        return {
          'success': false,
          'message': 'Your session has expired. Please login again.',
          'data': null,
        };
      } else {
        _logger.error('KTP sync failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to sync KTP data',
          'data': null,
        };
      }
    } catch (e) {
      _logger.error('KTP sync network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
}
