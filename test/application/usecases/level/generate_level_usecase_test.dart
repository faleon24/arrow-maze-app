import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/level/generate_level_usecase.dart';
import 'package:arrow_maze_app/domain/models/level.dart';
import 'package:arrow_maze_app/domain/ports/level_repository.dart';

class _FakeLevelRepository implements ILevelRepository {
  Level? nextGenerated;
  Object? nextGenerateError;
  String? capturedDifficulty;

  @override
  Future<List<Level>> fetchLevels() {
    throw UnimplementedError();
  }

  @override
  Future<Level> generate({required String difficulty}) async {
    capturedDifficulty = difficulty;
    if (nextGenerateError != null) throw nextGenerateError!;
    return nextGenerated!;
  }
}

void main() {
  group('GenerateLevelUseCase', () {
    test('should_delegate_to_repository_with_provided_difficulty', () async {
      // Arrange
      final repo = _FakeLevelRepository();
      final useCase = GenerateLevelUseCase(repo);

      // Act — the fake has no nextGenerated so the null-bang throws;
      // we swallow that to focus on the argument-passthrough assertion.
      try {
        await useCase(difficulty: 'MEDIUM');
      } catch (_) {}

      // Assert
      expect(repo.capturedDifficulty, 'MEDIUM');
    });

    test('should_propagate_error_when_repository_throws', () async {
      // Arrange
      final repo = _FakeLevelRepository()
        ..nextGenerateError = Exception('backend down');
      final useCase = GenerateLevelUseCase(repo);

      // Act + Assert
      await expectLater(
        useCase(difficulty: 'HARD'),
        throwsException,
      );
      expect(repo.capturedDifficulty, 'HARD');
    });
  });
}
