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

  /// The backend's type label, for debugging and rendering.
  String get typeLabel;
}

/// An open, walkable tile with nothing special on it.
class EmptyCell extends Cell {
  EmptyCell(super.position);
  @override
  bool get canTraverse => true;
  @override
  String get typeLabel => 'EMPTY';
}

/// An impassable tile.
class WallCell extends Cell {
  WallCell(super.position);
  @override
  bool get canTraverse => false;
  @override
  String get typeLabel => 'WALL';
}

/// The tile where the player starts.
class StartCell extends Cell {
  StartCell(super.position);
  @override
  bool get canTraverse => true;
  @override
  String get typeLabel => 'START';
}

/// The goal tile; reaching it completes the level.
class ExitCell extends Cell {
  ExitCell(super.position);
  @override
  bool get canTraverse => true;
  @override
  String get typeLabel => 'EXIT';
}

/// A tile that forces movement in a fixed Direction. The only cell that
/// carries extra data — a Direction strategy.
class ArrowCell extends Cell {
  final Direction direction;

  ArrowCell(super.position, this.direction);

  @override
  bool get canTraverse => true;
  @override
  String get typeLabel => 'ARROW';
}