import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class KtpService {
  static const String baseUrl = 'https://3580dc107926.ngrok-free.app/api/v1';

  Future<Map<String, dynamic>> uploadAndProcessKtp({
    required String userId,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/identity_card'),
      );

      // Add required headers for ngrok
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });

      // Add form fields
      request.fields['user_id'] = userId;

      // Add image file
      String fileName = imageFile.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Parse response
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'KTP processing failed',
          'data': null,
        };
      }
    } catch (e) {
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
      if (!imageFile.existsSync()) return false;

      // Check file size (max 5MB)
      int fileSizeInBytes = imageFile.lengthSync();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 5) return false;

      // Check file extension
      String extension = imageFile.path.toLowerCase().split('.').last;
      List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) return false;

      return true;
    } catch (e) {
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
}
