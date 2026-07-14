import '../../../domain/models/user_session.dart';
import '../../../domain/ports/auth_repository.dart';
import '../../../domain/ports/auth_token_storage.dart';

/// RegisterUseCase — orchestrates account creation.
///
/// Calls IAuthRepository.register and, on success, persists the
/// returned UserSession so the caller is immediately signed in.
class RegisterUseCase {
  final IAuthRepository _authRepo;
  final IAuthTokenStorage _tokenStorage;

  const RegisterUseCase(this._authRepo, this._tokenStorage);

  Future<UserSession> call({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final session = await _authRepo.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _tokenStorage.saveSession(
      token: session.token,
      expiresAt: session.expiresAt,
    );
    return session;
  }
}
