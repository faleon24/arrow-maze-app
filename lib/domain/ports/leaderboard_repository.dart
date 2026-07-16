import '../models/leaderboard_entry.dart';
import '../models/my_leaderboard_rank.dart';

/// ILeaderboardRepository — the domain-facing contract for
/// per-level leaderboards.
///
/// The backend records every run via the progress endpoint; this port
/// surfaces the reads the app needs: the level's top entries (public,
/// ordered by stars desc / time asc), and the authenticated player's
/// own rank on the level so it can be shown even when they fall outside
/// the visible top-N.
abstract class ILeaderboardRepository {
  /// Top entries for [levelId]. Backend accepts an optional limit
  /// (1-100). If null, backend default applies.
  Future<List<LeaderboardEntry>> fetchForLevel(
    String levelId, {
    int? limit,
  });

  /// The current player's rank + best run on [levelId], or null when
  /// there is no session or the player has not cleared the level yet.
  /// A read-only, optional signal — never throws on missing auth.
  Future<MyLeaderboardRank?> fetchMyRank(String levelId);
}
