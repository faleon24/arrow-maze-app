import '../../../domain/models/my_leaderboard_rank.dart';
import '../../../domain/ports/leaderboard_repository.dart';

/// GetMyLeaderboardRankUseCase — the current player's rank on a level.
///
/// Thin coordinator over the port. Returns null when there is no
/// session or the player has not cleared the level yet, so callers can
/// choose whether to show a personal-rank row.
class GetMyLeaderboardRankUseCase {
  final ILeaderboardRepository _repo;
  const GetMyLeaderboardRankUseCase(this._repo);
  Future<MyLeaderboardRank?> call({required String levelId}) =>
      _repo.fetchMyRank(levelId);
}
