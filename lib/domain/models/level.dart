import 'board.dart';

/// Level — the domain entity for a playable puzzle.
///
/// Lives in the domain layer so use cases and ports can reference it
/// without dragging http, JSON, or persistence types. Infrastructure
/// adapters (HTTP, local fixture) map their DTOs into this entity.
class Level {
  final String id;
  final int index;
  final String difficulty;
  final int parTimeMs;
  final int? timeLimitMs;
  final bool published;
  final Board board;

  const Level({
    required this.id,
    required this.index,
    required this.difficulty,
    required this.parTimeMs,
    this.timeLimitMs,
    required this.published,
    required this.board,
  });
}
