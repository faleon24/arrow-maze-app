import '../../../domain/ports/progress_repository.dart';

/// SubmitLevelResultUseCase — persists the outcome of a finished run.
///
/// The backend computes stars server-side from moves + timeMs against
/// the level's par, so no star count is submitted from the client
/// (the API's ValidationPipe would reject it as an extra property).
class SubmitLevelResultUseCase {
  final IProgressRepository _progressRepo;

  const SubmitLevelResultUseCase(this._progressRepo);

  Future<void> call({
    required String levelId,
    required int moves,
    required int timeMs,
  }) {
    return _progressRepo.submitScore(
      levelId: levelId,
      moves: moves,
      timeMs: timeMs,
    );
  }
}
