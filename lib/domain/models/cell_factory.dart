import 'cell.dart';
import 'direction.dart';
import 'position.dart';

/// DirectionFactory — Factory Method that turns the backend's direction
/// label ("UP"/"DOWN"/"LEFT"/"RIGHT") into the matching Direction
/// strategy instance. Callers depend only on the abstract Direction, so
/// the knowledge of "which label maps to which class" lives in one place.
class DirectionFactory {
  static Direction fromLabel(String label) {
    switch (label.toUpperCase()) {
      case 'UP':
        return UpDirection();
      case 'DOWN':
        return DownDirection();
      case 'LEFT':
        return LeftDirection();
      case 'RIGHT':
        return RightDirection();
      default:
        throw FormatException('Unknown direction: "$label"');
    }
  }
}

/// CellFactory — Factory Method (GoF, creational). The app-side twin of
/// the backend's DifficultyProfileFactory.
///
/// Turns one raw cell snapshot from the board JSON into the correct
/// concrete Cell subclass. Callers (the mapping from a LevelModel to the
/// playable board) depend only on the abstract Cell return type and never
/// name a concrete subclass, so adding a new cell type means changing
/// this one method and nothing else (OCP).
///
/// The whitelist is EMPTY / WALL / ARROW. START and EXIT existed in a
/// legacy v1 model and were dropped alongside the backend cell-type
/// refactor; unknown types (including START/EXIT) are rejected fast
/// with FormatException so a stale seed cannot silently succeed.
class CellFactory {
  /// Build a Cell from its JSON shape, e.g.
  /// { "position": "1,1", "type": "WALL" } or
  /// { "position": "0,2", "type": "ARROW", "direction": "DOWN" }.
  static Cell fromJson(Map<String, dynamic> json) {
    final position = Position.parse(json['position'] as String);
    final type = (json['type'] as String).toUpperCase();
    switch (type) {
      case 'EMPTY':
        return EmptyCell(position);
      case 'WALL':
        return WallCell(position);
      case 'ARROW':
        final directionLabel = json['direction'] as String?;
        if (directionLabel == null) {
          throw const FormatException('Arrow cell missing direction');
        }
        return ArrowCell(position, DirectionFactory.fromLabel(directionLabel));
      default:
        throw FormatException('Unknown cell type: "$type"');
    }
  }
}
