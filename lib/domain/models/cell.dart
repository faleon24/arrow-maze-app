import 'direction.dart';
import 'position.dart';

/// Cell — the abstract base of the board cell hierarchy (the UML's
/// `Cell <Component>`).
///
/// Each cell knows its position and whether the player can step on it.
/// Modeling cells as polymorphic types (instead of one class with a
/// nullable direction) keeps each variant honest: only ArrowCell carries
/// a Direction, and only because it needs one.
abstract class Cell {
  final Position position;
  Cell(this.position);

  /// Can the player occupy this cell?
  bool get canTraverse;
}

/// An open, walkable tile with nothing special on it.
class EmptyCell extends Cell {
  EmptyCell(super.position);
  @override
  bool get canTraverse => true;
}

/// An impassable tile. Kept in the hierarchy even though the current
/// gameplay never places one, because PLAN-MASTER Fase 4 revives it:
/// v2 arrow paths need walls to block their rays. Removing the class
/// now would only force us to reintroduce it in three weeks.
class WallCell extends Cell {
  WallCell(super.position);
  @override
  bool get canTraverse => false;
}

/// A tile that forces movement in a fixed Direction. The only cell that
/// carries extra data — a Direction strategy.
class ArrowCell extends Cell {
  final Direction direction;
  ArrowCell(super.position, this.direction);
  @override
  bool get canTraverse => true;
}
