import '../../domain/models/my_leaderboard_rank.dart';
import 'leaderboard_entry_dto.dart';

/// MyRankDto — transport shape for the authenticated player's rank on a
/// level. Mirrors the backend's MyRankResponseDto ({ rank, entry }),
/// reusing LeaderboardEntryDto for the nested run.
class MyRankDto {
  final int rank;
  final LeaderboardEntryDto entry;
  const MyRankDto({required this.rank, required this.entry});

  factory MyRankDto.fromJson(Map<String, dynamic> json) => MyRankDto(
        rank: json['rank'] as int,
        entry: LeaderboardEntryDto.fromJson(
          json['entry'] as Map<String, dynamic>,
        ),
      );

  MyLeaderboardRank toDomain() =>
      MyLeaderboardRank(rank: rank, entry: entry.toDomain());
}
