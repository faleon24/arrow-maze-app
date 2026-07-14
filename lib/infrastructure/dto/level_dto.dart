import '../../domain/models/board.dart';
import '../../domain/models/board_builder.dart';
import '../../domain/models/level.dart';

/// LevelDto — transport shape returned by GET /levels (v2 contract).
/// Board is parsed at DTO construction so a malformed fixture fails
/// fast with the same FormatException prod code raises. toDomain()
/// projects into the Level entity that application/presentation see.
class LevelDto {
  final String id;
  final int index;
  final String difficulty;
  final int parTimeMs;
  final int? timeLimitMs;
  final bool published;
  final Board board;

  LevelDto({
    required this.id,
    required this.index,
    required this.difficulty,
    required this.parTimeMs,
    this.timeLimitMs,
    required this.published,
    required this.board,
  });

  factory LevelDto.fromJson(Map<String, dynamic> json) {
    return LevelDto(
      id: json['id'] as String,
      index: json['index'] as int,
      difficulty: json['difficulty'] as String,
      parTimeMs: json['parTimeMs'] as int,
      timeLimitMs: json['timeLimitMs'] as int?,
      published: json['published'] as bool,
      board: BoardBuilder.fromJson(json['board'] as Map<String, dynamic>),
    );
  }

  Level toDomain() => Level(
        id: id,
        index: index,
        difficulty: difficulty,
        parTimeMs: parTimeMs,
        timeLimitMs: timeLimitMs,
        published: published,
        board: board,
      );
}
