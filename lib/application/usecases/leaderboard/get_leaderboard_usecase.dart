import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/ports/leaderboard_repository.dart';

class GetLeaderboardUseCase {
  final ILeaderboardRepository _repo;

  const GetLeaderboardUseCase(this._repo);

  Future<List<LeaderboardEntry>> call({
    required String levelId,
    int? limit,
  }) =>
      _repo.fetchForLevel(levelId, limit: limit);
}
