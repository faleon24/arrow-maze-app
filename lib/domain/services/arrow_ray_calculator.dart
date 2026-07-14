
import '../models/board.dart';
import '../models/position.dart';

/// ArrowRayCalculator — pure domain logic that computes the cells a
/// given arrow's ray would traverse.
///
/// Same walk as GameSession's activation ray, but returns the cell
/// list instead of a boolean. Extracted so power-up features (grid
/// highlight) can render the ray without triggering activation.
class ArrowRayCalculator {
  const ArrowRayCalculator();

  /// Positions the ray from the arrow with [arrowId] would traverse,
  /// stopping just before it exits the board or hits a wall or a
  /// foreign arrow. Returns an empty list if [arrowId] is unknown.
  List<Position> rayCells(Board board, String arrowId) {
    final arrow = board.arrows
        .cast<dynamic>()
        .firstWhere((a) => a.id == arrowId, orElse: () => null);
    if (arrow == null) return const <Position>[];

    final cells = <Position>[];
    var next = arrow.direction.apply(arrow.head);
    while (board.contains(next)) {
      if (board.isWall(next)) break;
      final foreign = board.arrowAt(next);
      if (foreign != null && foreign.id != arrowId) break;
      cells.add(next);
      next = arrow.direction.apply(next);
    }
    return cells;
  }
}
