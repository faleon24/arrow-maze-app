import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/auth_token_storage.dart';

/// SharedPrefsTokenStorage — persists the authenticated session
/// (token + expiry) using shared_preferences. Not encrypted; a
/// secure-storage adapter is scheduled but out of scope for this
/// refactor.
class SharedPrefsTokenStorage implements IAuthTokenStorage {
  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at';

  const SharedPrefsTokenStorage();

  @override
  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_expiresAtKey, expiresAt.millisecondsSinceEpoch);
  }

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<DateTime?> readExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_expiresAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
  }
}
