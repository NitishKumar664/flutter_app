import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles credential storage and the HTTP Basic Auth header the server's
/// requireAuth middleware already accepts (see server.js) — no backend
/// changes were needed to support this app.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _storage = const FlutterSecureStorage();

  static const _kServerUrl = 'server_url';
  static const _kUsername = 'username';
  static const _kPassword = 'password';

  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    // Normalize: strip trailing slash so we can safely do "$serverUrl/api/..."
    final normalized = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    await _storage.write(key: _kServerUrl, value: normalized);
    await _storage.write(key: _kUsername, value: username);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kServerUrl);
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kPassword);
  }

  Future<String?> getServerUrl() => _storage.read(key: _kServerUrl);
  Future<String?> getUsername() => _storage.read(key: _kUsername);
  Future<String?> getPassword() => _storage.read(key: _kPassword);

  Future<bool> isLoggedIn() async {
    final url = await getServerUrl();
    final user = await getUsername();
    return url != null && url.isNotEmpty && user != null && user.isNotEmpty;
  }

  /// Builds the "Basic base64(user:pass)" header value the server expects.
  Future<String?> basicAuthHeader() async {
    final user = await getUsername();
    final pass = await getPassword();
    if (user == null || pass == null) return null;
    final encoded = base64Encode(utf8.encode('$user:$pass'));
    return 'Basic $encoded';
  }
}
