import 'board.dart';
import 'cell.dart';
import 'position.dart';

class TapOutcome {
  final String value;
  const TapOutcome._(this.value);

  static const cleared = TapOutcome._('CLEARED');
  static const blocked = TapOutcome._('BLOCKED');
  static const notAnArrow = TapOutcome._('NOT_AN_ARROW');
}
/// GameSession — the state and rules of a single play-through of a level.
///
/// This is the heart of Arrow Maze. The board is full of arrows; the
/// player taps them to make them fly off. An arrow can only escape if
/// its "exit ray" — the straight line from the arrow to the edge in the
/// direction it points — is completely clear of other arrows. Clearing
/// an arrow empties its cell, which may unblock its neighbours. The goal
/// is to clear every arrow before running out of moves or lives.
///
/// All the game rules live here, in the domain, free of Flutter and HTTP.
/// The UI calls tap() and reacts to the returned outcome and this
/// session's state; it never re-implements a rule.
class GameSession {
  Board board;
  final int moveLimit;
  final int maxLives;

  int movesUsed;
  int lives;

  GameSession({
    required this.board,
    required this.moveLimit,
    this.maxLives = 3,
  })  : movesUsed = 0,
        lives = maxLives;

  /// Is the arrow at this position free to escape? True only if the cell
  /// holds an arrow AND every cell along its exit ray (to the edge) is
  /// clear of other arrows. This is the core rule of the game.
  bool isActivatable(Position arrowPosition) {
    final cell = board.cellAt(arrowPosition);
    if (cell is! ArrowCell) return false;

    // Trace the ray outward, one step at a time, in the arrow's
    // direction. The Direction strategy knows how to step; this method
    // never branches on which way the arrow points.
    var next = cell.direction.apply(arrowPosition);
    while (board.contains(next)) {
      if (board.cellAt(next) is ArrowCell) {
        return false; // another arrow blocks the ray
      }
      next = cell.direction.apply(next);
    }
    return true; // reached the edge with a clear path
  }

  /// Attempt to tap a cell. Returns what happened. Every tap on an arrow
  /// counts as a move; a blocked tap also costs a life. Tapping a
  /// non-arrow cell does nothing and costs neither.
  TapOutcome tap(Position position) {
    final cell = board.cellAt(position);

    if (cell is! ArrowCell) {
      return TapOutcome.notAnArrow;
    }

    movesUsed++;

    if (isActivatable(position)) {
      _removeArrow(position);
      return TapOutcome.cleared;
    } else {
      lives--;
      return TapOutcome.blocked;
    }
  }

  /// The board is solved when no arrows remain.
  bool get isCleared => board.arrows.isEmpty;

  /// The game is lost if lives run out or the move limit is reached with
  /// arrows still on the board.
  bool get isFailed =>
      !isCleared && (lives <= 0 || movesUsed >= moveLimit);

  /// How many arrows are still on the board.
  int get arrowsRemaining => board.arrows.length;

  // ---------- Internal ----------

  /// Remove an arrow by rebuilding the board's cell map without it. The
  /// vacated cell becomes empty space, which may free its neighbours.
  void _removeArrow(Position position) {
    final newCells = Map<Position, Cell>.from(board.cells);
    newCells.remove(position);
    board = Board(rows: board.rows, cols: board.cols, cells: newCells);
  }
}