import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/level/get_levels_usecase.dart';
import 'package:arrow_maze_app/application/usecases/level/load_levels_catalog_usecase.dart';
import 'package:arrow_maze_app/application/usecases/progress/get_stars_by_level_usecase.dart';
import 'package:arrow_maze_app/domain/models/level.dart';
import 'package:arrow_maze_app/domain/ports/level_repository.dart';
import 'package:arrow_maze_app/domain/ports/progress_repository.dart';

class _FakeLevelRepository implements ILevelRepository {
  List<Level>? nextResult;
  Object? nextError;

  @override
  Future<List<Level>> fetchLevels() async {
    if (nextError != null) throw nextError!;
    return nextResult!;
  }
}

class _FakeProgressRepository implements IProgressRepository {
  Map<String, int>? nextStars;
  Object? nextStarsError;

  @override
  Future<Map<String, int>> fetchStarsByLevel() async {
    if (nextStarsError != null) throw nextStarsError!;
    return nextStars!;
  }

  @override
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('LoadLevelsCatalogUseCase', () {
    test('should_include_stars_when_both_repos_succeed', () async {
      // Arrange
      final levelRepo = _FakeLevelRepository()..nextResult = <Level>[];
      final progressRepo = _FakeProgressRepository()
        ..nextStars = {'level-a': 3};
      final useCase = LoadLevelsCatalogUseCase(
        GetLevelsUseCase(levelRepo),
        GetStarsByLevelUseCase(progressRepo),
      );

      // Act
      final catalog = await useCase();

      // Assert
      expect(catalog.levels, isEmpty);
      expect(catalog.starsByLevel, {'level-a': 3});
    });

    test('should_return_empty_stars_when_progress_repo_fails', () async {
      // Arrange
      final levelRepo = _FakeLevelRepository()..nextResult = <Level>[];
      final progressRepo = _FakeProgressRepository()
        ..nextStarsError = Exception('unauthorized');
      final useCase = LoadLevelsCatalogUseCase(
        GetLevelsUseCase(levelRepo),
        GetStarsByLevelUseCase(progressRepo),
      );

      // Act
      final catalog = await useCase();

      // Assert
      expect(catalog.levels, isEmpty);
      expect(catalog.starsByLevel, isEmpty);
    });

    test('should_propagate_error_when_level_repo_fails', () async {
      // Arrange
      final levelRepo = _FakeLevelRepository()
        ..nextError = Exception('boom');
      final progressRepo = _FakeProgressRepository()..nextStars = {};
      final useCase = LoadLevelsCatalogUseCase(
        GetLevelsUseCase(levelRepo),
        GetStarsByLevelUseCase(progressRepo),
      );

      // Act + Assert
      await expectLater(useCase(), throwsException);
    });
  });
}
