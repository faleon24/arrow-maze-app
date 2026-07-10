import 'dart:convert';
import 'package:http/http.dart' as http;

import '../auth_storage.dart';

/// ProgressApi — the data-layer client for the protected /me/progress
/// endpoints. Unlike LevelApi (public), every call here must carry the
/// bearer token, which it reads from AuthStorage and puts in the
/// Authorization header.
class ProgressApi {
  static const String _baseUrl = 'http://localhost:3000/api';
  final AuthStorage _storage = AuthStorage();

  /// Submit a completed run. Returns nothing useful to the caller beyond
  /// success; the backend keeps the best score. Throws on failure
  /// (including 401 if the token is missing or expired).
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

    final response = await http.post(
      Uri.parse('$_baseUrl/me/progress'),
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
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit score (HTTP ${response.statusCode})');
    }
  }
}