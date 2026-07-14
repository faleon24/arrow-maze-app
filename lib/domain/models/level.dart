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

  /// Minimum stars required in this level for the NEXT level to unlock.
  ///
  /// Mirrors the backend's DifficultyProfile.unlockThreshold() values.
  /// Kept as a static helper (not a subclass hierarchy) because the
  /// app receives the difficulty as a plain label from the wire and
  /// only needs the threshold — no other polymorphic behavior.
  static int unlockThresholdFor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 1;
      case 'MEDIUM':
        return 2;
      case 'HARD':
        return 3;
      default:
        return 3;
    }
  }

  /// The threshold this level applies to its successor.
  int get unlockThreshold => unlockThresholdFor(difficulty);
}
