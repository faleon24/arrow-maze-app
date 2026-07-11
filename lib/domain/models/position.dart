/// Position — an immutable row/column coordinate on the board.
///
/// The backend sends positions as the string "row,col"; this class
/// parses that form and offers value equality so two positions with the
/// same coordinates are treated as equal (needed to look cells up by
/// position).
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Parse the "row,col" string the backend stores for each cell.
  factory Position.parse(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) {
      throw FormatException('Invalid position: "$raw"');
    }
    return Position(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Value equality: two Positions are equal iff their coordinates match.
  /// Overriding == and hashCode lets Position be used as a Map key.
  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '$row,$col';
}
