import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_storage.dart';
import 'api_config.dart';
/// ProgressApi — the data-layer client for the protected /me/progress
/// endpoints. Unlike LevelApi (public), every call here must carry the
/// bearer token, which it reads from AuthStorage and puts in the
/// Authorization header.
class ProgressApi {
  final AuthStorage _storage = AuthStorage();
  /// Submit a completed run. Returns nothing useful to the caller
  /// beyond success; the backend keeps the best score. Throws on
  /// failure (including 401 if the token is missing or expired).
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
    required int stars,
  }) async {
    final token = await _storage.readToken();
    if (token == null) {
      throw Exception('Not signed in');
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
      throw Exception('Failed to submit score (HTTP ${response.statusCode})');
    }
  }
  /// Fetch the player's progress as a map of levelId -> stars, so the
  /// levels list can show how many stars each level was cleared with.
  /// Returns an empty map if the user has no progress yet.
  Future<Map<String, int>> fetchStarsByLevel() async {
    final token = await _storage.readToken();
    if (token == null) {
      throw Exception('Not signed in');
    }
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/me/progress'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load progress (HTTP ${response.statusCode})');
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