import '../models/user_session.dart';

/// IAuthRepository — the domain-facing contract for authentication.
///
/// Application use cases depend on this interface, not on any HTTP
/// client. The concrete adapter lives in
/// lib/infrastructure/adapters/http/auth_http_adapter.dart.
abstract class IAuthRepository {
  Future<UserSession> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserSession> login({
    required String email,
    required String password,
  });
}
