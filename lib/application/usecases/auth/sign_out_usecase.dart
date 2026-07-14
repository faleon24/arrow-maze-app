import '../../../domain/ports/auth_token_storage.dart';

/// SignOutUseCase — clears the persisted session.
///
/// Trivial today but exists so screens ask "sign the user out" instead
/// of "call clearSession on the storage adapter", keeping the intent
/// explicit and giving a single place to attach side effects later
/// (analytics, cache invalidation, etc.).
class SignOutUseCase {
  final IAuthTokenStorage _tokenStorage;

  const SignOutUseCase(this._tokenStorage);

  Future<void> call() async {
    await _tokenStorage.clearSession();
  }
}
