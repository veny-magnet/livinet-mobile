import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for sensitive data
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  static SecureStorage get instance => _instance;
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage Keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserCode = 'user_code';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  // Token Management
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // User Data Management
  Future<void> saveUserCode(String userCode) async {
    await _storage.write(key: _keyUserCode, value: userCode);
  }

  Future<String?> getUserCode() async {
    return await _storage.read(key: _keyUserCode);
  }

  // Deprecated: Use getUserCode() instead - kept for backwards compatibility
  Future<void> saveUserId(String userId) async {
    await saveUserCode(userId);
  }

  Future<String?> getUserId() async {
    return await getUserCode();
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  // Generic Storage Methods
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Clear Methods
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> clearUserData() async {
    await _storage.delete(key: _keyUserCode);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserName);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Get all stored keys (for debugging only - use carefully)
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
