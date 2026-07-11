import 'package:shared_preferences/shared_preferences.dart';
/// AuthStorage — persists the authenticated session (token + expiry)
/// across app launches using shared_preferences.
///
/// Design note: shared_preferences is chosen for simplicity. A
/// production build would keep a JWT in flutter_secure_storage instead,
/// since preferences are not encrypted. That migration is scheduled for
/// PLAN-MASTER Fase 9.3 (SecureAuthStorage adapter).
///
/// Persisting the expiry lets AuthGate reject a locally-expired token
/// on launch without a doomed round-trip to the backend, and lets
/// UI code display a "session expired" state without inspecting JWT
/// internals.
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at';
  /// Persist a full authenticated session after a successful login or
  /// register. Token and expiry are stored together so a partial state
  /// (token without expiry, or vice versa) is unreachable.
  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_expiresAtKey, expiresAt.millisecondsSinceEpoch);
  }
  /// Read the stored token, or null if the user is not signed in.
  /// Vigencia is NOT enforced here — callers that care about expiry
  /// (AuthGate, hypothetically ProgressApi) also read readExpiresAt.
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  /// Read the persisted expiry, or null if none is stored.
  Future<DateTime?> readExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_expiresAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
  /// Remove every trace of the persisted session (log out).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
  }
}