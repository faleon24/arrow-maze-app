import '../../domain/models/board.dart';

/// LevelModel — the data-layer representation of a level from the
/// backend's GET /api/levels endpoint.
///
/// Beyond the scalar fields, it now carries the playable Board, built
/// from the backend's board JSON via Board.fromJson (which runs the
/// CellFactory on each cell). This is the seam where flat backend data
/// becomes the app's polymorphic domain.
class LevelModel {
  final String id;
  final int index;
  final String difficulty;
  final int parTimeMs;
  final bool published;
  final Board board;

  LevelModel({
    required this.id,
    required this.index,
    required this.difficulty,
    required this.parTimeMs,
    required this.published,
    required this.board,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      index: json['index'] as int,
      difficulty: json['difficulty'] as String,
      parTimeMs: json['parTimeMs'] as int,
      published: json['published'] as bool,
      board: Board.fromJson(json['board'] as Map<String, dynamic>),
    );
  }
}
