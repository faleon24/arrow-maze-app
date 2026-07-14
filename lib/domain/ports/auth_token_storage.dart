/// IAuthTokenStorage — the domain-facing contract for locally persisting
/// the authenticated session across launches.
///
/// The default binding uses shared_preferences; a secure implementation
/// (flutter_secure_storage) is scheduled but out of scope for this
/// refactor. Application use cases only see this interface.
abstract class IAuthTokenStorage {
  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  });

  Future<String?> readToken();

  Future<DateTime?> readExpiresAt();

  Future<void> clearSession();
}
