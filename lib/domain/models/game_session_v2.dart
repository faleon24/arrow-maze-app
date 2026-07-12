import 'arrow_path.dart';
import 'board_v2.dart';
import 'collectible.dart';
import 'position.dart';

/// TapOutcome — what a tap resolved to. Modeled as a small hierarchy
/// (project constraint: no enums). v1 declared the same shape; the two
/// coexist because they live in separate files and no caller imports
/// both. When v1 is retired in Phase 5 this becomes the sole definition.
class TapOutcome {
  final String value;
  const TapOutcome._(this.value);
  static const cleared = TapOutcome._('CLEARED');
  static const blocked = TapOutcome._('BLOCKED');
  static const notAnArrow = TapOutcome._('NOT_AN_ARROW');
}

/// GameSession — v2 state and rules of a single play-through.
///
/// The v2 model swaps single-cell arrows for [ArrowPath]s and adds walls
/// and collectibles. Core rule survives: an arrow fires only if the ray
/// from its head to the grid edge, in its direction, is clear of walls
/// and of any other arrow's cells. Any cell of the arrow's path is a
/// valid tap target — the whole path clears as one unit. Collectibles
/// sitting on the ray are gathered when the arrow fires; they do not
/// block the ray.
///
/// The board is treated as immutable: clearing an arrow rebuilds it into
/// a new [Board] without the cleared path and without collected pickups.
/// Rebuild cost is O(arrows+walls+collectibles) per clear, fine for the
/// small boards this game uses. A future optimization (a mutable working
/// board with delta ops) is deferred until profiling asks for it.
class GameSession {
  Board board;
  final int moveLimit;
  final int maxLives;
  int movesUsed;
  int lives;

  /// Positions of collectibles gathered during this session. Consumed by
  /// star/score computation and by the UI to celebrate pickups.
  final Set<Position> collectedPositions;

  GameSession({
    required this.board,
    required this.moveLimit,
    this.maxLives = 3,
  })  : movesUsed = 0,
        lives = maxLives,
        collectedPositions = <Position>{};

  /// Is the arrow with [arrowId] free to fire? True only if a ray from
  /// its head, stepping in its direction, reaches the grid edge without
  /// hitting a wall or another arrow's cells. Unknown ids and empty
  /// boards yield false.
  bool isActivatable(String arrowId) {
    final arrow = _findArrow(arrowId);
    if (arrow == null) return false;
    var next = arrow.direction.apply(arrow.head);
    while (board.contains(next)) {
      if (board.isWall(next)) return false;
      final foreign = board.arrowAt(next);
      // The ray steps outward from head, so it never re-enters this
      // arrow's own cells — any arrow found on the path is another one.
      if (foreign != null && foreign.id != arrowId) return false;
      next = arrow.direction.apply(next);
    }
    return true;
  }

  /// Tap a board position. Returns what happened. A tap on a non-arrow
  /// cell is free; a tap on an arrow always costs a move, and costs a
  /// life too if the ray is blocked.
  TapOutcome tap(Position position) {
    final arrow = board.arrowAt(position);
    if (arrow == null) return TapOutcome.notAnArrow;

    movesUsed++;
    if (!isActivatable(arrow.id)) {
      lives--;
      return TapOutcome.blocked;
    }

    _clearArrow(arrow);
    return TapOutcome.cleared;
  }

  ArrowPath? _findArrow(String id) {
    for (final a in board.arrows) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Vacate an arrow's cells and pick up every collectible along its ray.
  /// Rebuilds [board] into a fresh immutable Board with the remainder.
  void _clearArrow(ArrowPath arrow) {
    final gathered = <Position>{};
    var next = arrow.direction.apply(arrow.head);
    while (board.contains(next)) {
      final c = board.collectibleAt(next);
      if (c != null) gathered.add(next);
      next = arrow.direction.apply(next);
    }

    final remainingArrows =
        board.arrows.where((a) => a.id != arrow.id).toList();
    final remainingCollectibles = <Position, Collectible>{
      for (final entry in board.collectibles.entries)
        if (!gathered.contains(entry.key)) entry.key: entry.value,
    };

    board = Board(
      rows: board.rows,
      cols: board.cols,
      arrows: remainingArrows,
      walls: board.walls,
      collectibles: remainingCollectibles,
    );

    collectedPositions.addAll(gathered);
  }

  /// True when every arrow has been cleared.
  bool get isCleared => board.arrows.isEmpty;

  /// True when the run is unwinnable: no lives, or move budget spent
  /// while arrows still stand.
  bool get isFailed => !isCleared && (lives <= 0 || movesUsed >= moveLimit);

  int get arrowsRemaining => board.arrows.length;

  int get starsEarned {
    final livesLost = maxLives - lives;
    final stars = 3 - livesLost;
    return stars < 1 ? 1 : stars;
  }
}