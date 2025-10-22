import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/app_config.dart';

/// SSL Pinning Service
/// Provides HTTP client with certificate pinning for enhanced security
class SSLPinningService {
  static final SSLPinningService _instance = SSLPinningService._internal();
  static SSLPinningService get instance => _instance;
  SSLPinningService._internal();

  final _config = AppConfig.instance;
  http.Client? _client;

  /// Certificate fingerprints (SHA-256)
  /// Generate using: openssl x509 -noout -fingerprint -sha256 -inform pem -in certificate.crt
  static const List<String> _certificateFingerprints = [
    // Add your production SSL certificate fingerprints here
    // Example: 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99'
  ];

  /// Public key hashes (SHA-256) - Alternative to certificate pinning
  static const List<String> _publicKeyHashes = [
    // Add your public key hashes here
    // Can be extracted from certificate using:
    // openssl x509 -in certificate.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  ];

  /// Get HTTP client with SSL pinning
  http.Client getClient() {
    if (_client != null) {
      return _client!;
    }

    // Only enable SSL pinning in production
    if (_config.isProduction && _certificateFingerprints.isNotEmpty) {
      _client = _createPinnedClient();
    } else {
      _client = http.Client();
    }

    return _client!;
  }

  /// Create HTTP client with SSL pinning
  http.Client _createPinnedClient() {
    final httpClient = HttpClient();

    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          // In production, verify certificate
          if (_config.isProduction) {
            return _verifyCertificate(cert, host);
          }
          // In development, allow self-signed certificates
          return true;
        };

    return IOClient(httpClient);
  }

  /// Verify SSL certificate against pinned fingerprints
  bool _verifyCertificate(X509Certificate cert, String host) {
    // Get certificate DER bytes
    final certDER = cert.der;

    // Compute SHA-256 hash
    final digest = sha256.convert(certDER);
    final certSHA256 = digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');

    // Check if certificate fingerprint matches any pinned certificates
    if (_certificateFingerprints.contains(certSHA256)) {
      return true;
    }

    return false;
  }

  /// Close the client
  void dispose() {
    _client?.close();
    _client = null;
  }

  /// Test SSL connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final client = getClient();
      final response = await client
          .get(Uri.parse('${_config.baseUrl}/health'))
          .timeout(const Duration(seconds: 10));

      return {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'ssl_pinning_enabled':
            _config.isProduction && _certificateFingerprints.isNotEmpty,
        'message': response.statusCode == 200
            ? 'Connection successful'
            : 'Connection failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'ssl_pinning_enabled':
            _config.isProduction && _certificateFingerprints.isNotEmpty,
      };
    }
  }

  /// Get certificate info for debugging (development only)
  Future<Map<String, dynamic>?> getCertificateInfo(String url) async {
    if (_config.isProduction) {
      return null; // Don't expose certificate info in production
    }

    try {
      final uri = Uri.parse(url);
      final socket = await SecureSocket.connect(
        uri.host,
        uri.port != 0 ? uri.port : 443,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (cert) => true, // Allow for inspection
      );

      final cert = socket.peerCertificate;
      socket.close();

      if (cert == null) {
        return null;
      }

      // Compute SHA-256 from DER
      final certDER = cert.der;
      final digest = sha256.convert(certDER);
      final sha256Hash = digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');

      return {
        'subject': cert.subject,
        'issuer': cert.issuer,
        'start_date': cert.startValidity.toIso8601String(),
        'end_date': cert.endValidity.toIso8601String(),
        'sha256_fingerprint': sha256Hash,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
