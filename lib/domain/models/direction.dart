import 'position.dart';

/// Direction — Strategy for the four ways an arrow can point.
///
/// Modeled as a class hierarchy rather than an enum (a project
/// constraint, and the design the UML calls for): each direction knows
/// how it moves a position and how to render itself. Behavior lives in
/// the type, so callers never switch over a direction — they just ask it.
abstract class Direction {
  /// Move a position one step in this direction.
  Position apply(Position from);

  /// The arrow glyph used to draw this direction.
  String get symbol;

  /// The backend's string label for this direction (UP/DOWN/LEFT/RIGHT).
  String get label;
}

class UpDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row - 1, from.col);
  @override
  String get symbol => '↑';
  @override
  String get label => 'UP';
}

class DownDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row + 1, from.col);
  @override
  String get symbol => '↓';
  @override
  String get label => 'DOWN';
}

class LeftDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row, from.col - 1);
  @override
  String get symbol => '←';
  @override
  String get label => 'LEFT';
}

class RightDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row, from.col + 1);
  @override
  String get symbol => '→';
  @override
  String get label => 'RIGHT';
}