import '../../domain/models/user_session.dart';

/// AuthResponseDto — transport shape returned by /auth/register and
/// /auth/login. Lives in infrastructure/dto because it is coupled to
/// the JSON wire format. Maps to the domain UserSession via toDomain().
class AuthResponseDto {
  final String token;
  final DateTime expiresAt;

  const AuthResponseDto({required this.token, required this.expiresAt});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  UserSession toDomain() =>
      UserSession(token: token, expiresAt: expiresAt);
}
