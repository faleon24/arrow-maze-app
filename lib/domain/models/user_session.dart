/// UserSession — the domain value object for an authenticated session.
///
/// Wraps the bearer token and its absolute expiry. Immutable. Auth
/// adapters return this shape; the token storage port persists and
/// restores it.
class UserSession {
  final String token;
  final DateTime expiresAt;

  const UserSession({required this.token, required this.expiresAt});

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}
