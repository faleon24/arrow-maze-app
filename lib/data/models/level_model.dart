import '../../domain/models/board.dart';
import '../../domain/models/board_builder.dart';

/// LevelModel — the data-layer representation of a level from the
/// backend's GET /api/levels endpoint (v2 contract).
///
/// v2 changes: [board] is now the arrow-path Board built by
/// [BoardBuilder.fromJson], which validates structural invariants at
/// construction. [timeLimitMs] is new — the backend serves it optional
/// per level (null means no time cap).
class LevelModel {
  final String id;
  final int index;
  final String difficulty;
  final int parTimeMs;
  final int? timeLimitMs;
  final bool published;
  final Board board;

  LevelModel({
    required this.id,
    required this.index,
    required this.difficulty,
    required this.parTimeMs,
    this.timeLimitMs,
    required this.published,
    required this.board,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      index: json['index'] as int,
      difficulty: json['difficulty'] as String,
      parTimeMs: json['parTimeMs'] as int,
      timeLimitMs: json['timeLimitMs'] as int?,
      published: json['published'] as bool,
      board: BoardBuilder.fromJson(json['board'] as Map<String, dynamic>),
    );
  }
}