/// IProgressRepository — the domain-facing contract for the player's
/// progress store.
///
/// Requires an authenticated session; the adapter is responsible for
/// injecting the bearer token. Application use cases stay ignorant of
/// authentication mechanics.
abstract class IProgressRepository {
  Future<void> submitScore({
    required String levelId,
    required int moves,
    required int timeMs,
  });

  Future<Map<String, int>> fetchStarsByLevel();
}
