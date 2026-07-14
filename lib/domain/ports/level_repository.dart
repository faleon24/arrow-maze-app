import '../models/level.dart';

/// ILevelRepository — the domain-facing contract for the level catalog.
///
/// The default binding in DI resolves to the HTTP adapter; a fixture
/// adapter binding is used when USE_DEV_LEVELS is set. Application
/// use cases (GetLevelsUseCase, GetLevelByIdUseCase) depend on this
/// port and never see either concrete implementation.
abstract class ILevelRepository {
  Future<List<Level>> fetchLevels();
}
