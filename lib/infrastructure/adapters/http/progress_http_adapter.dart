import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/ports/auth_token_storage.dart';
import '../../../domain/ports/progress_repository.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// ProgressHttpAdapter — HTTP implementation of IProgressRepository.
/// Requires an authenticated session; reads the bearer token via the
/// injected IAuthTokenStorage. Throws UnauthorizedException if there
/// is no local token or the backend returns 401.
class ProgressHttpAdapter implements IProgressRepository {
  final IAuthTokenStorage _tokenStorage;

  const ProgressHttpAdapter(this._tokenStorage);

  @override
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
  }) async {
    final token = await _tokenStorage.readToken();
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
          }),
        )
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<Map<String, int>> fetchStarsByLevel() async {
    final token = await _tokenStorage.readToken();
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
