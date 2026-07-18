import 'arrow_color.dart';
import 'arrow_path.dart';
import 'board.dart';
import 'direction.dart';
import 'collectible.dart';
import 'position.dart';

/// BoardBuilder — GoF Builder for the v2 [Board].
///
/// Board's constructor is raw: it trusts callers to already hold valid
/// domain pieces. The Builder is where all structural invariants are
/// enforced, so any Board that came out of a [build] call is guaranteed
/// consistent:
///
///   * every arrow, wall and collectible fits inside the grid;
///   * arrow cells are contiguous *and* each step matches the arrow's
///     direction (no gaps, no perpendicular turns);
///   * arrow ids are unique across the board;
///   * arrows, walls and collectibles never share a cell.
///
/// The API is fluent (each step returns [this]) so a hand-built board
/// reads top-to-bottom. The static [fromJson] entry parses the backend's
/// board JSON and delegates to the same validating pipeline — one path
/// for tests, another for level data, same invariants.
class BoardBuilder {
  int? _rows;
  int? _cols;
  final List<ArrowPath> _arrows = [];
  final Set<Position> _walls = {};
  final Map<Position, Collectible> _collectibles = {};

  BoardBuilder withDimensions(int rows, int cols) {
    if (rows <= 0 || cols <= 0) {
      throw FormatException(
        'Board dimensions must be positive: got ${rows}x$cols',
      );
    }
    _rows = rows;
    _cols = cols;
    return this;
  }

  BoardBuilder addArrow(ArrowPath arrow) {
    _requireDimensions('arrow "${arrow.id}"');
    _validateCellsInBounds(arrow.cells, 'arrow "${arrow.id}"');
    _validateArrowContiguous(arrow);
    _validateArrowIdUnique(arrow);
    _validateNoOverlapWithBoard(arrow.cells, 'arrow "${arrow.id}"');
    _arrows.add(arrow);
    return this;
  }

  BoardBuilder addWall(Position position) {
    _requireDimensions('wall');
    _validateCellsInBounds([position], 'wall');
    _validateNoOverlapWithBoard([position], 'wall at $position');
    _walls.add(position);
    return this;
  }

  BoardBuilder addCollectible(Collectible collectible) {
    _requireDimensions('collectible');
    _validateCellsInBounds([collectible.position], 'collectible');
    _validateNoOverlapWithBoard(
      [collectible.position],
      'collectible at ${collectible.position}',
    );
    _collectibles[collectible.position] = collectible;
    return this;
  }

  Board build() {
    if (_rows == null || _cols == null) {
      throw StateError('BoardBuilder.build called before withDimensions');
    }
    return Board(
      rows: _rows!,
      cols: _cols!,
      arrows: _arrows,
      walls: _walls,
      collectibles: _collectibles,
    );
  }

  /// Parse the backend's board JSON into a fully-validated Board. Any
  /// structural violation surfaces as [FormatException] with a message
  /// pointing to the offending piece — cheap postmortem when a seed or
  /// fixture drifts out of shape.
  static Board fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 2) {
      throw FormatException(
        'Unsupported board version: $version (expected 2)',
      );
    }

    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final builder = BoardBuilder().withDimensions(rows, cols);

    for (final raw in (json['arrows'] as List<dynamic>? ?? const [])) {
      builder.addArrow(_arrowFromJson(raw as Map<String, dynamic>));
    }
    for (final raw in (json['walls'] as List<dynamic>? ?? const [])) {
      builder.addWall(Position.parse(raw as String));
    }
    for (final raw in (json['collectibles'] as List<dynamic>? ?? const [])) {
      final map = raw as Map<String, dynamic>;
      builder.addCollectible(
        Collectible(
          position: Position.parse(map['position'] as String),
          kind: map['kind'] as String,
        ),
      );
    }
    return builder.build();
  }

  static ArrowPath _arrowFromJson(Map<String, dynamic> json) {
    return ArrowPath(
      id: json['id'] as String,
      color: ArrowColorFactory.fromLabel(json['color'] as String),
      cells: (json['cells'] as List<dynamic>)
          .map((raw) => Position.parse(raw as String))
          .toList(),
      direction: DirectionFactory.fromLabel(json['direction'] as String),
    );
  }

  // === Invariants ===

  void _requireDimensions(String owner) {
    if (_rows == null || _cols == null) {
      throw StateError('BoardBuilder missing dimensions before adding $owner');
    }
  }

  void _validateCellsInBounds(List<Position> cells, String owner) {
    for (final cell in cells) {
      if (cell.row < 0 ||
          cell.row >= _rows! ||
          cell.col < 0 ||
          cell.col >= _cols!) {
        throw FormatException(
          'Position $cell for $owner falls outside ${_rows}x$_cols grid',
        );
      }
    }
  }

  static const List<String> _hexLabels = ['E', 'W', 'NE', 'NW', 'SE', 'SW'];

  void _validateArrowContiguous(ArrowPath arrow) {
    for (var i = 0; i < arrow.cells.length - 1; i++) {
      final prev = arrow.cells[i];
      final curr = arrow.cells[i + 1];
      final adjacent = _hexLabels.any(
        (d) => DirectionFactory.fromLabel(d).apply(prev) == curr,
      );
      if (!adjacent) {
        throw FormatException(
          'Arrow "${arrow.id}" cells must be hex-adjacent (odd-r offset); '
          '$prev to $curr is not a neighbour',
        );
      }
    }
  }

  void _validateArrowIdUnique(ArrowPath arrow) {
    for (final existing in _arrows) {
      if (existing.id == arrow.id) {
        throw FormatException('Duplicate arrow id: "${arrow.id}"');
      }
    }
  }

  void _validateNoOverlapWithBoard(List<Position> cells, String owner) {
    for (final cell in cells) {
      if (_walls.contains(cell)) {
        throw FormatException('$owner overlaps a wall at $cell');
      }
      if (_collectibles.containsKey(cell)) {
        throw FormatException('$owner overlaps a collectible at $cell');
      }
      for (final existing in _arrows) {
        if (existing.cells.contains(cell)) {
          throw FormatException(
            '$owner overlaps arrow "${existing.id}" at $cell',
          );
        }
      }
    }
  }
}