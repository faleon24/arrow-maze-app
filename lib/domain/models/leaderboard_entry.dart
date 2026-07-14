/// LeaderboardEntry — one row in a per-level leaderboard.
///
/// Immutable value object. Fields mirror the backend's
/// LeaderboardEntryResponseDto shape, with the ISO string parsed
/// into a DateTime at the DTO boundary.
class LeaderboardEntry {
  final String userDisplayName;
  final int stars;
  final int timeMs;
  final DateTime completedAt;

  const LeaderboardEntry({
    required this.userDisplayName,
    required this.stars,
    required this.timeMs,
    required this.completedAt,
  });
}
