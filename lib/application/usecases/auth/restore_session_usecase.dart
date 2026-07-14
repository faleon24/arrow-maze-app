import '../../../domain/models/user_session.dart';
import '../../../domain/ports/auth_token_storage.dart';

/// RestoreSessionUseCase — reads the persisted session and validates
/// its expiry.
///
/// Returns the UserSession if a non-expired one is present. Returns
/// null (and clears the storage) if the token is missing, the expiry
/// is missing, or the expiry is in the past. This is what AuthGate
/// uses to decide whether to route into the app or to the login screen
/// on launch.
///
/// `now` is injectable so tests can drive the clock deterministically.
class RestoreSessionUseCase {
  final IAuthTokenStorage _tokenStorage;

  const RestoreSessionUseCase(this._tokenStorage);

  Future<UserSession?> call({DateTime? now}) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    final expiresAt = await _tokenStorage.readExpiresAt();
    if (expiresAt == null) {
      await _tokenStorage.clearSession();
      return null;
    }

    final session = UserSession(token: token, expiresAt: expiresAt);
    final currentTime = now ?? DateTime.now();
    if (session.isExpiredAt(currentTime)) {
      await _tokenStorage.clearSession();
      return null;
    }
    return session;
  }
}
