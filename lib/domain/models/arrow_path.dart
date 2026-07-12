import 'arrow_color.dart';
import 'direction.dart';
import 'position.dart';

/// ArrowPath — a chain of contiguous board cells that behave as one
/// arrow. The last cell is the head: where the ray originates and where
/// the arrow glyph is drawn. Every cell in the path shares the same
/// color and direction.
///
/// Value object: immutable, equality by fields. Contiguity of [cells]
/// and their alignment with [direction] are board-level invariants and
/// live in BoardBuilder, not here — the VO stays cheap to construct in
/// tests and callers can always trust a built path.
class ArrowPath {
  final String id;
  final ArrowColor color;
  final List<Position> cells;
  final Direction direction;

  ArrowPath({
    required this.id,
    required this.color,
    required List<Position> cells,
    required this.direction,
  }) : cells = List.unmodifiable(cells) {
    if (this.cells.isEmpty) {
      throw ArgumentError('ArrowPath must span at least one cell');
    }
  }

  /// The leading cell — where the ray starts and the glyph sits. For a
  /// degenerate 1-cell path (v1 arrows lifted into v2) head == cells.first.
  Position get head => cells.last;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ArrowPath) return false;
    if (id != other.id) return false;
    if (color.name != other.color.name) return false;
    if (direction.label != other.direction.label) return false;
    if (cells.length != other.cells.length) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        color.name,
        direction.label,
        Object.hashAll(cells),
      );
}