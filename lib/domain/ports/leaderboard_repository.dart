import '../models/leaderboard_entry.dart';

/// ILeaderboardRepository — the domain-facing contract for
/// per-level leaderboards.
///
/// Read-only from the app's perspective. The backend records every
/// run via the progress endpoint; this port surfaces the top entries
/// for a level, ordered by stars desc / time asc.
abstract class ILeaderboardRepository {
  /// Top entries for [levelId]. Backend accepts an optional limit
  /// (1-100). If null, backend default applies.
  Future<List<LeaderboardEntry>> fetchForLevel(
    String levelId, {
    int? limit,
  });
}
