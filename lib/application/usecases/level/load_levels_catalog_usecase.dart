import '../../../domain/models/level.dart';
import '../progress/get_stars_by_level_usecase.dart';
import 'get_levels_usecase.dart';

/// LevelsCatalog — the value object LevelsScreen renders: every
/// published level plus the stars the player has earned on each.
class LevelsCatalog {
  final List<Level> levels;
  final Map<String, int> starsByLevel;
  const LevelsCatalog({
    required this.levels,
    required this.starsByLevel,
  });
}

/// LoadLevelsCatalogUseCase — composes GetLevelsUseCase and
/// GetStarsByLevelUseCase, loading both in parallel and tolerating
/// a failed stars fetch (network hiccup, expired token) by returning
/// an empty starsByLevel map. Levels error propagates.
class LoadLevelsCatalogUseCase {
  final GetLevelsUseCase _getLevels;
  final GetStarsByLevelUseCase _getStars;

  const LoadLevelsCatalogUseCase(this._getLevels, this._getStars);

  Future<LevelsCatalog> call() async {
    final levelsFuture = _getLevels();
    final starsFuture = _getStars().catchError(
      (Object _) => <String, int>{},
    );
    return LevelsCatalog(
      levels: await levelsFuture,
      starsByLevel: await starsFuture,
    );
  }
}
