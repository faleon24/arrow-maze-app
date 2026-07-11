import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import 'api_config.dart';
import 'api_exception.dart';
/// AuthApi — the data-layer client for the backend's /auth endpoints.
///
/// On a non-2xx status it throws an ApiException carrying the backend's
/// message field, so the UI can display it directly. Manual message
/// extraction and the "Exception: " string-slicing that used to live
/// here now sit inside ApiException.fromResponse.
class AuthApi {
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _post('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
  }
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return _post('/auth/login', {
      'email': email,
      'password': password,
    });
  }
  Future<AuthResponse> _post(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException.fromResponse(response);
  }
}