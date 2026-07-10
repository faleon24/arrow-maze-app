import 'package:shared_preferences/shared_preferences.dart';

/// AuthStorage — persists the auth token across app launches using
/// shared_preferences (a simple key-value store).
///
/// Design note: shared_preferences is chosen for simplicity. A
/// production app would keep a JWT in secure storage
/// (flutter_secure_storage) instead, since preferences are not
/// encrypted; for this project's scope, this is sufficient.
class AuthStorage {
  static const _tokenKey = 'auth_token';

  /// Save the token after a successful login/register.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Read the stored token, or null if the user is not logged in.
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove the token (log out).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}