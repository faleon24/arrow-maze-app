import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/progress/get_stars_by_level_usecase.dart';
import 'package:arrow_maze_app/domain/ports/progress_repository.dart';

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
  group('GetStarsByLevelUseCase', () {
    test('should_return_stars_when_repository_returns', () async {
      // Arrange
      final repo = _FakeProgressRepository()
        ..nextStars = {'level-a': 2, 'level-b': 3};
      final useCase = GetStarsByLevelUseCase(repo);

      // Act
      final stars = await useCase();

      // Assert
      expect(stars, {'level-a': 2, 'level-b': 3});
    });

    test('should_propagate_error_when_repository_throws', () async {
      // Arrange
      final repo = _FakeProgressRepository()..nextStarsError = Exception();
      final useCase = GetStarsByLevelUseCase(repo);

      // Act + Assert
      await expectLater(useCase(), throwsException);
    });
  });
}
