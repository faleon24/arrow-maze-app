import '../models/level.dart';

/// ILevelRepository — the domain-facing contract for the level catalog.
///
/// The default binding in DI resolves to the HTTP adapter; a fixture
/// adapter binding is used when USE_DEV_LEVELS is set. Application
/// use cases (GetLevelsUseCase, LoadLevelsCatalogUseCase,
/// GenerateLevelUseCase) depend on this port and never see either
/// concrete implementation.
abstract class ILevelRepository {
  Future<List<Level>> fetchLevels();

  /// Request the server to procedurally generate and persist a new
  /// level of the given difficulty. Returns the freshly created level.
  /// The offline fixture adapter cannot fulfil this — it throws
  /// UnsupportedError so callers know to require network.
  Future<Level> generate({required String difficulty});
}
