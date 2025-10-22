import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secure_storage.dart';
import 'token_refresh_service.dart';

/// HTTP client with automatic token refresh
class AuthenticatedHttpClient {
  static final AuthenticatedHttpClient _instance =
      AuthenticatedHttpClient._internal();
  static AuthenticatedHttpClient get instance => _instance;
  AuthenticatedHttpClient._internal();

  final _secureStorage = SecureStorage.instance;
  final _tokenRefreshService = TokenRefreshService.instance;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  /// Make GET request with automatic token refresh
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _makeRequest(
      () => http.get(url, headers: headers),
      url,
      'GET',
      headers: headers,
    );
  }

  /// Make POST request with automatic token refresh
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeRequest(
      () => http.post(url, headers: headers, body: body, encoding: encoding),
      url,
      'POST',
      headers: headers,
      body: body,
    );
  }

  /// Make PUT request with automatic token refresh
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeRequest(
      () => http.put(url, headers: headers, body: body, encoding: encoding),
      url,
      'PUT',
      headers: headers,
      body: body,
    );
  }

  /// Make DELETE request with automatic token refresh
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _makeRequest(
      () => http.delete(url, headers: headers, body: body, encoding: encoding),
      url,
      'DELETE',
      headers: headers,
      body: body,
    );
  }

  /// Core request handler with retry logic
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction,
    Uri url,
    String method, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await requestFunction();

      // Check if token expired (401 Unauthorized)
      if (response.statusCode == 401) {
        // If already refreshing, queue this request
        if (_isRefreshing) {
          return _queueRequest(
            requestFunction,
            url,
            method,
            headers: headers,
            body: body,
          );
        }

        // Try to refresh token
        _isRefreshing = true;
        final refreshResult = await _tokenRefreshService.refreshToken();
        _isRefreshing = false;

        if (refreshResult['success'] == true) {
          // Retry original request with new token
          final token = await _secureStorage.getAccessToken();
          final newHeaders = Map<String, String>.from(headers ?? {});
          if (token != null) {
            newHeaders['Authorization'] = 'Bearer $token';
          }

          // Retry the request
          final retryResponse = await _retryRequest(
            method,
            url,
            newHeaders,
            body,
          );

          // Process all pending requests
          _processPendingRequests();

          return retryResponse;
        } else {
          // Refresh failed, clear pending requests
          _clearPendingRequests();
          return response; // Return original 401 response
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Queue request while token is being refreshed
  Future<http.Response> _queueRequest(
    Future<http.Response> Function() requestFunction,
    Uri url,
    String method, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final pendingRequest = _PendingRequest(
      requestFunction: requestFunction,
      url: url,
      method: method,
      headers: headers,
      body: body,
    );

    _pendingRequests.add(pendingRequest);
    return pendingRequest.completer.future;
  }

  /// Retry request with new token
  Future<http.Response> _retryRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Object? body,
  ) async {
    switch (method) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: body);
      case 'PUT':
        return http.put(url, headers: headers, body: body);
      case 'DELETE':
        return http.delete(url, headers: headers, body: body);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  /// Process all pending requests after token refresh
  Future<void> _processPendingRequests() async {
    final token = await _secureStorage.getAccessToken();

    for (final request in _pendingRequests) {
      try {
        final headers = Map<String, String>.from(request.headers ?? {});
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        final response = await _retryRequest(
          request.method,
          request.url,
          headers,
          request.body,
        );

        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }

    _pendingRequests.clear();
  }

  /// Clear all pending requests
  void _clearPendingRequests() {
    for (final request in _pendingRequests) {
      request.completer.completeError(Exception('Token refresh failed'));
    }
    _pendingRequests.clear();
  }
}

/// Pending request holder
class _PendingRequest {
  final Future<http.Response> Function() requestFunction;
  final Uri url;
  final String method;
  final Map<String, String>? headers;
  final Object? body;
  final completer = Completer<http.Response>();

  _PendingRequest({
    required this.requestFunction,
    required this.url,
    required this.method,
    this.headers,
    this.body,
  });
}
