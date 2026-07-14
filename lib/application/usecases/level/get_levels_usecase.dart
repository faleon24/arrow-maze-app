import '../../../domain/models/level.dart';
import '../../../domain/ports/level_repository.dart';

/// GetLevelsUseCase — fetches the full published catalog via the port.
///
/// A thin wrapper today; the value is semantic — screens depend on
/// "get me the levels" instead of on the concrete repository type.
class GetLevelsUseCase {
  final ILevelRepository _levelRepo;

  const GetLevelsUseCase(this._levelRepo);

  Future<List<Level>> call() => _levelRepo.fetchLevels();
}
