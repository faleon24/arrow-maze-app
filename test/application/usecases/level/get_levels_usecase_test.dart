import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/level/get_levels_usecase.dart';
import 'package:arrow_maze_app/domain/models/level.dart';
import 'package:arrow_maze_app/domain/ports/level_repository.dart';

class _FakeLevelRepository implements ILevelRepository {
  List<Level>? nextResult;
  Object? nextError;

  @override
  Future<List<Level>> fetchLevels() async {
    if (nextError != null) throw nextError!;
    return nextResult!;
  }
}

void main() {
  group('GetLevelsUseCase', () {
    test('should_return_levels_when_repository_returns', () async {
      // Arrange
      final repo = _FakeLevelRepository()..nextResult = <Level>[];
      final useCase = GetLevelsUseCase(repo);

      // Act
      final levels = await useCase();

      // Assert
      expect(levels, isEmpty);
    });

    test('should_propagate_error_when_repository_throws', () async {
      // Arrange
      final repo = _FakeLevelRepository()..nextError = Exception('boom');
      final useCase = GetLevelsUseCase(repo);

      // Act + Assert
      await expectLater(useCase(), throwsException);
    });
  });
}
