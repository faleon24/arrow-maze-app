import 'position.dart';

/// Direction — Strategy for the 6 ways an arrow can point on a hex board
/// (odd-r offset). apply() is parity-aware: the neighbour depends on
/// whether the current row is even or odd. No enums (project rule).
abstract class Direction {
  Position apply(Position from);
  String get symbol;
  String get label;
}

class EastDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row, from.col + 1);
  @override
  String get symbol => '→';
  @override
  String get label => 'E';
}

class WestDirection extends Direction {
  @override
  Position apply(Position from) => Position(from.row, from.col - 1);
  @override
  String get symbol => '←';
  @override
  String get label => 'W';
}

class NorthEastDirection extends Direction {
  @override
  Position apply(Position from) {
    final even = from.row % 2 == 0;
    return Position(from.row - 1, even ? from.col : from.col + 1);
  }
  @override
  String get symbol => '↗';
  @override
  String get label => 'NE';
}

class NorthWestDirection extends Direction {
  @override
  Position apply(Position from) {
    final even = from.row % 2 == 0;
    return Position(from.row - 1, even ? from.col - 1 : from.col);
  }
  @override
  String get symbol => '↖';
  @override
  String get label => 'NW';
}

class SouthEastDirection extends Direction {
  @override
  Position apply(Position from) {
    final even = from.row % 2 == 0;
    return Position(from.row + 1, even ? from.col : from.col + 1);
  }
  @override
  String get symbol => '↘';
  @override
  String get label => 'SE';
}

class SouthWestDirection extends Direction {
  @override
  Position apply(Position from) {
    final even = from.row % 2 == 0;
    return Position(from.row + 1, even ? from.col - 1 : from.col);
  }
  @override
  String get symbol => '↙';
  @override
  String get label => 'SW';
}

class DirectionFactory {
  static Direction fromLabel(String label) {
    switch (label.toUpperCase()) {
      case 'E':
        return EastDirection();
      case 'W':
        return WestDirection();
      case 'NE':
        return NorthEastDirection();
      case 'NW':
        return NorthWestDirection();
      case 'SE':
        return SouthEastDirection();
      case 'SW':
        return SouthWestDirection();
      default:
        throw FormatException('Unknown direction: "$label"');
    }
  }
}
