import '../../../domain/models/user_session.dart';
import '../../../domain/ports/auth_repository.dart';
import '../../../domain/ports/auth_token_storage.dart';

/// SignInUseCase — orchestrates authenticated sign-in.
///
/// Calls IAuthRepository.login and, on success, persists the returned
/// UserSession via IAuthTokenStorage. Both effects are the responsibility
/// of this single use case so that screens do not have to know that
/// "logging in" is really two steps.
class SignInUseCase {
  final IAuthRepository _authRepo;
  final IAuthTokenStorage _tokenStorage;

  const SignInUseCase(this._authRepo, this._tokenStorage);

  Future<UserSession> call({
    required String email,
    required String password,
  }) async {
    final session = await _authRepo.login(email: email, password: password);
    await _tokenStorage.saveSession(
      token: session.token,
      expiresAt: session.expiresAt,
    );
    return session;
  }
}
