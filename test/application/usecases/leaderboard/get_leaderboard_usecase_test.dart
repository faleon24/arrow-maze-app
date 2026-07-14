import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/leaderboard/get_leaderboard_usecase.dart';
import 'package:arrow_maze_app/domain/models/leaderboard_entry.dart';
import 'package:arrow_maze_app/domain/ports/leaderboard_repository.dart';

class _FakeLeaderboardRepo implements ILeaderboardRepository {
  List<LeaderboardEntry>? nextResult;
  Object? nextError;
  String? capturedLevelId;
  int? capturedLimit;

  @override
  Future<List<LeaderboardEntry>> fetchForLevel(
    String levelId, {
    int? limit,
  }) async {
    capturedLevelId = levelId;
    capturedLimit = limit;
    if (nextError != null) throw nextError!;
    return nextResult ?? const [];
  }
}

void main() {
  group('GetLeaderboardUseCase', () {
    test('should_pass_levelId_and_limit_through_to_repository', () async {
      final repo = _FakeLeaderboardRepo()..nextResult = const [];
      final useCase = GetLeaderboardUseCase(repo);

      await useCase(levelId: 'lvl-42', limit: 10);

      expect(repo.capturedLevelId, 'lvl-42');
      expect(repo.capturedLimit, 10);
    });

    test('should_return_the_repository_result_when_successful', () async {
      final entry = LeaderboardEntry(
        userDisplayName: 'Alice',
        stars: 3,
        timeMs: 12_000,
        completedAt: DateTime.utc(2026, 1, 1),
      );
      final repo = _FakeLeaderboardRepo()..nextResult = [entry];
      final useCase = GetLeaderboardUseCase(repo);

      final result = await useCase(levelId: 'x');

      expect(result, [entry]);
    });

    test('should_propagate_error_when_repository_throws', () async {
      final repo = _FakeLeaderboardRepo()
        ..nextError = Exception('boom');
      final useCase = GetLeaderboardUseCase(repo);

      await expectLater(useCase(levelId: 'x'), throwsException);
    });
  });
}
