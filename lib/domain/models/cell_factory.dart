import 'cell.dart';
import 'direction.dart';
import 'position.dart';


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