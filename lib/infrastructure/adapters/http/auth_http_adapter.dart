import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/user_session.dart';
import '../../../domain/ports/auth_repository.dart';
import '../../dto/auth_response_dto.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// AuthHttpAdapter — HTTP implementation of IAuthRepository.
/// Talks to /auth/register and /auth/login. Throws ApiException on
/// non-2xx (UnauthorizedException on 401).
class AuthHttpAdapter implements IAuthRepository {
  const AuthHttpAdapter();

  @override
  Future<UserSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final dto = await _post('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return dto.toDomain();
  }

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final dto = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return dto.toDomain();
  }

  Future<AuthResponseDto> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponseDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(response);
  }
}
