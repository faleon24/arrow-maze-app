import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/leaderboard/get_my_leaderboard_rank_usecase.dart';
import 'package:arrow_maze_app/domain/models/leaderboard_entry.dart';
import 'package:arrow_maze_app/domain/models/my_leaderboard_rank.dart';
import 'package:arrow_maze_app/domain/ports/leaderboard_repository.dart';
class _FakeLeaderboardRepo implements ILeaderboardRepository {
  MyLeaderboardRank? nextRank;
  String? capturedLevelId;
  @override
  Future<List<LeaderboardEntry>> fetchForLevel(
    String levelId, {
    int? limit,
  }) async =>
      const [];
  @override
  Future<MyLeaderboardRank?> fetchMyRank(String levelId) async {
    capturedLevelId = levelId;
    return nextRank;
  }
}
void main() {
  group('GetMyLeaderboardRankUseCase', () {
    test('should_return_rank_when_repository_has_a_run', () async {
      final rank = MyLeaderboardRank(
        rank: 7,
        entry: LeaderboardEntry(
          userDisplayName: 'Alice',
          stars: 3,
          timeMs: 12_000,
          completedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final repo = _FakeLeaderboardRepo()..nextRank = rank;
      final useCase = GetMyLeaderboardRankUseCase(repo);
      final result = await useCase(levelId: 'lvl-42');
      expect(result, rank);
      expect(repo.capturedLevelId, 'lvl-42');
    });
    test('should_return_null_when_repository_has_no_run', () async {
      final repo = _FakeLeaderboardRepo();
      final useCase = GetMyLeaderboardRankUseCase(repo);
      final result = await useCase(levelId: 'x');
      expect(result, isNull);
    });
  });
}
