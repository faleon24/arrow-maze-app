import 'leaderboard_entry.dart';

/// MyLeaderboardRank — the current player's standing on one level.
///
/// Immutable value object pairing the player's best run (entry) with
/// its 1-based position (rank) under the leaderboard ordering. The port
/// returns null instead of this when the player has no run on the level
/// yet, so "not played" is distinct from "ranked".
class MyLeaderboardRank {
  final int rank;
  final LeaderboardEntry entry;
  const MyLeaderboardRank({required this.rank, required this.entry});
}
