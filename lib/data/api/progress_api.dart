import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';
/// ProgressApi — the data-layer client for the protected /me/progress
/// endpoints. Every call must carry the bearer token; if the token is
/// missing locally or the backend returns 401, an UnauthorizedException
/// is thrown so the caller (later, a global handler) can force logout.
class ProgressApi {
  final AuthStorage _storage = AuthStorage();
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
    required int stars,
  }) async {
    final token = await _storage.readToken();
    if (token == null) {
      throw const UnauthorizedException('Not signed in');
    }
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/me/progress'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'levelId': levelId,
            'moves': moves,
            'timeMs': timeMs,
            'stars': stars,
          }),
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(response);
    }
  }
  Future<Map<String, int>> fetchStarsByLevel() async {
    final token = await _storage.readToken();
    if (token == null) {
      throw const UnauthorizedException('Not signed in');
    }
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/me/progress'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final entries = decoded['entries'] as List<dynamic>;
    final result = <String, int>{};
    for (final entry in entries) {
      final map = entry as Map<String, dynamic>;
      result[map['levelId'] as String] = map['stars'] as int;
    }
    return result;
  }
}