/// AuthResponse — the data-layer representation of a successful
/// register or login, as returned by the backend's /auth endpoints.
///
/// The backend returns just the bearer token and its expiry; there is no
/// user object in the body. The token is what every protected request
/// (progress, etc.) must carry in its Authorization header.
class AuthResponse {
  final String token;
  final DateTime expiresAt;

  AuthResponse({required this.token, required this.expiresAt});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
