import '../../domain/models/leaderboard_entry.dart';

/// LeaderboardEntryDto — transport shape for one leaderboard row.
/// Mirrors the backend's LeaderboardEntryResponseDto.
class LeaderboardEntryDto {
  final String userDisplayName;
  final int stars;
  final int timeMs;
  final String completedAt;

  const LeaderboardEntryDto({
    required this.userDisplayName,
    required this.stars,
    required this.timeMs,
    required this.completedAt,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryDto(
      userDisplayName: json['userDisplayName'] as String,
      stars: json['stars'] as int,
      timeMs: json['timeMs'] as int,
      completedAt: json['completedAt'] as String,
    );
  }

  LeaderboardEntry toDomain() => LeaderboardEntry(
        userDisplayName: userDisplayName,
        stars: stars,
        timeMs: timeMs,
        completedAt: DateTime.parse(completedAt),
      );
}
