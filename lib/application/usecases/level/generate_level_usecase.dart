import '../../../domain/models/level.dart';
import '../../../domain/ports/level_repository.dart';

/// GenerateLevelUseCase — asks the server to procedurally generate a
/// new level of the given difficulty and returns the freshly persisted
/// puzzle. Fires against the backend's POST /levels/generate endpoint;
/// the fixture adapter throws UnsupportedError, so this use case
/// requires an online session.
class GenerateLevelUseCase {
  final ILevelRepository _levelRepo;

  const GenerateLevelUseCase(this._levelRepo);

  Future<Level> call({required String difficulty}) =>
      _levelRepo.generate(difficulty: difficulty);
}
