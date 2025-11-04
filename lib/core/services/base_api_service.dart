import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class BaseApiService {
  final _config = AppConfig.instance;
  final _logger = AppLogger.instance;

  // These should be configured according to your Laravel API requirements
  String get apiServer => _config.apiServer;
  String get apiKey => _config.apiKey;

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'name_server': apiServer,
    'key_server': apiKey,
  };

  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = Map<String, String>.from(_baseHeaders);

    // Add bearer token if available
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _logger.error('Error getting auth token', e);
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(
        '${_config.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);

      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      _logger.apiRequest(
        method: 'GET',
        endpoint: uri.toString(),
        headers: requestHeaders,
      );

      final stopwatch = Stopwatch()..start();
      final response = await http.get(uri, headers: requestHeaders);
      stopwatch.stop();

      _logger.apiResponse(
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e, stack) {
      _logger.error('No internet connection', e, stack);
      throw ApiException('No internet connection');
    } on HttpException catch (e, stack) {
      _logger.error('HTTP error occurred', e, stack);
      throw ApiException('HTTP error occurred');
    } catch (e, stack) {
      _logger.error('Unexpected error in GET request', e, stack);
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final requestHeaders = await _getHeaders(additionalHeaders: headers);

      _logger.apiRequest(
        method: 'POST',
        endpoint: '${_config.baseUrl}$endpoint',
        headers: requestHeaders,
        body: body,
      );

      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        Uri.parse('${_config.baseUrl}$endpoint'),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();

      _logger.apiResponse(
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e, stack) {
      _logger.error('No internet connection', e, stack);
      throw ApiException('No internet connection');
    } on HttpException catch (e, stack) {
      _logger.error('HTTP error occurred', e, stack);
      throw ApiException('HTTP error occurred');
    } catch (e, stack) {
      _logger.error('Unexpected error in POST request', e, stack);
      throw ApiException('Unexpected error: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    _logger.info('BaseApiService: Response status: ${response.statusCode}');
    _logger.debug('BaseApiService: Response body: ${response.body}');

    final Map<String, dynamic> jsonResponse;

    try {
      jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _logger.error('BaseApiService: Failed to parse JSON', e);
      _logger.info('BaseApiService: Raw response body: ${response.body}');
      throw ApiException('Invalid JSON response', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.fromJson(jsonResponse, fromJson);
    } else {
      final message = jsonResponse['message'] as String? ?? 'Unknown error';
      _logger.error(
        'BaseApiService: Error response - Status: ${response.statusCode}, Message: $message',
      );

      // For 500 errors, include more details
      if (response.statusCode == 500) {
        final exception = jsonResponse['exception'] as String?;
        final file = jsonResponse['file'] as String?;
        final line = jsonResponse['line'] as int?;

        if (exception != null) {
          _logger.error('BaseApiService: Server Exception: $exception');
          _logger.info('BaseApiService: File: $file:$line');
        }

        throw ApiException('System Error. $message', response.statusCode);
      }

      throw ApiException(message, response.statusCode);
    }
  }
}
