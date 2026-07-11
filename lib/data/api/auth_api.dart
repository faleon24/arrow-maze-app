import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import 'api_config.dart';
/// AuthApi — the data-layer client for the backend's /auth endpoints.
///
/// Register and login both return an AuthResponse (token + expiry). On
/// a non-2xx status it throws with the server's message so the UI can
/// show why (e.g. "email already registered", "invalid credentials").
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
    // Surface the backend's error message when possible.
    String message = 'Request failed (HTTP ${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      // Body wasn't JSON; keep the generic message.
    }
    throw Exception(message);
  }
}