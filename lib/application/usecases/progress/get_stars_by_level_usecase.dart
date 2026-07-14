import '../../../domain/ports/progress_repository.dart';

/// GetStarsByLevelUseCase — fetches how many stars the signed-in
/// player has earned per level.
///
/// Propagates errors verbatim; callers that want to tolerate a failed
/// progress fetch (e.g. the levels catalog composite) wrap this in
/// their own catchError.
class GetStarsByLevelUseCase {
  final IProgressRepository _progressRepo;

  const GetStarsByLevelUseCase(this._progressRepo);

  Future<Map<String, int>> call() => _progressRepo.fetchStarsByLevel();
}
