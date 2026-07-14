import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/progress/submit_level_result_usecase.dart';
import 'package:arrow_maze_app/domain/ports/progress_repository.dart';

class _FakeProgressRepository implements IProgressRepository {
  String? capturedLevelId;
  int? capturedMoves;
  int? capturedTimeMs;
  Object? nextError;

  @override
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
  }) async {
    capturedLevelId = levelId;
    capturedMoves = moves;
    capturedTimeMs = timeMs;
    if (nextError != null) throw nextError!;
  }

  @override
  Future<Map<String, int>> fetchStarsByLevel() {
    throw UnimplementedError();
  }
}

void main() {
  group('SubmitLevelResultUseCase', () {
    test('should_pass_args_to_repository_when_called', () async {
      // Arrange
      final repo = _FakeProgressRepository();
      final useCase = SubmitLevelResultUseCase(repo);

      // Act
      await useCase(levelId: 'lvl-42', moves: 7, timeMs: 3400);

      // Assert
      expect(repo.capturedLevelId, 'lvl-42');
      expect(repo.capturedMoves, 7);
      expect(repo.capturedTimeMs, 3400);
    });

    test('should_propagate_error_when_repository_throws', () async {
      // Arrange
      final repo = _FakeProgressRepository()..nextError = Exception();
      final useCase = SubmitLevelResultUseCase(repo);

      // Act + Assert
      await expectLater(
        useCase(levelId: 'x', moves: 0, timeMs: 0),
        throwsException,
      );
    });
  });
}
