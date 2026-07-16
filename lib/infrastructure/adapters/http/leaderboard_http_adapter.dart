import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/models/my_leaderboard_rank.dart';
import '../../../domain/ports/auth_token_storage.dart';
import '../../../domain/ports/leaderboard_repository.dart';
import '../../dto/leaderboard_entry_dto.dart';
import '../../dto/my_rank_dto.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// LeaderboardHttpAdapter — HTTP implementation of ILeaderboardRepository.
///
/// The board read (fetchForLevel) is public — no token required. The
/// personal rank read (fetchMyRank) hits an authenticated route and so
/// reads the bearer token via IAuthTokenStorage. Because a personal rank
/// is optional, decorative information, a missing session or a 401/empty
/// response is mapped to null rather than surfaced as an error.
class LeaderboardHttpAdapter implements ILeaderboardRepository {
  final IAuthTokenStorage _tokenStorage;
  const LeaderboardHttpAdapter(this._tokenStorage);

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

  @override
  Future<MyLeaderboardRank?> fetchMyRank(String levelId) async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}/leaderboard/$levelId/me');
    final response = await http
        .get(url, headers: {'Authorization': 'Bearer $token'})
        .timeout(ApiConfig.requestTimeout);
    // Empty body (HTTP 200), 204, or 401 all mean "no personal rank".
    if (response.statusCode == 401 || response.statusCode == 204) return null;
    if (response.statusCode == 200 && response.body.trim().isEmpty) return null;
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MyRankDto.fromJson(json).toDomain();
  }
}
