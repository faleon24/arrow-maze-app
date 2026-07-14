import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/ports/leaderboard_repository.dart';
import '../../dto/leaderboard_entry_dto.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// LeaderboardHttpAdapter — HTTP implementation of
/// ILeaderboardRepository. Public endpoint, no auth token required.
class LeaderboardHttpAdapter implements ILeaderboardRepository {
  const LeaderboardHttpAdapter();

  @override
  Future<List<LeaderboardEntry>> fetchForLevel(
    String levelId, {
    int? limit,
  }) async {
    final baseUrl = '${ApiConfig.baseUrl}/leaderboard/$levelId';
    final url = limit == null
        ? Uri.parse(baseUrl)
        : Uri.parse('$baseUrl?limit=$limit');
    final response = await http.get(url).timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (item) => LeaderboardEntryDto.fromJson(item as Map<String, dynamic>)
              .toDomain(),
        )
        .toList();
  }
}
