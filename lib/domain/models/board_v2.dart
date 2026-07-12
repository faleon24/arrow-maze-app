import 'arrow_path.dart';
import 'collectible.dart';
import 'position.dart';

/// Board — the v2 playable grid: a rectangle carved into arrow-paths,
/// walls and collectibles.
///
/// v2 replaces the v1 cell-typed model: arrows are now [ArrowPath]s
/// spanning one or more contiguous cells and behaving as a unit; walls
/// are [Position]s in a set; collectibles sit on individual positions
/// and are gathered when an arrow's ray passes over them.
///
/// The Board precomputes an occupancy index at construction so tap-time
/// lookups ([arrowAt], [isWall], [collectibleAt], [isEmpty]) run in O(1).
/// All exposed collections are unmodifiable snapshots — a Board cannot
/// be mutated after it exists.
///
/// The canonical way to build one from JSON is [BoardBuilder] (sub-block
/// 4.5), which validates structural invariants (no overlaps, arrow cells
/// contiguous and aligned with direction, ids unique). This constructor
/// is raw: it trusts the caller to guarantee those invariants. Tests
/// that hold pre-built domain pieces use it directly; production code
/// should go through the Builder.
class Board {
  final int rows;
  final int cols;
  final List<ArrowPath> arrows;
  final Set<Position> walls;
  final Map<Position, Collectible> collectibles;

  /// Owner of every occupied position: an arrow's id, or the sentinel
  /// [_wallOwner]. Empty positions are absent from the map, so
  /// membership is enough to decide "occupied?".
  final Map<Position, String> _occupancy;

  /// Arrow-by-id index so [arrowAt] resolves without scanning [arrows].
  final Map<String, ArrowPath> _arrowById;

  /// Sentinel stored in [_occupancy] for wall positions. Any string
  /// distinct from all arrow ids works; 'WALL' is picked for readability
  /// if the map ever leaks into a debug print.
  static const String _wallOwner = 'WALL';

  Board({
    required this.rows,
    required this.cols,
    required List<ArrowPath> arrows,
    required Set<Position> walls,
    required Map<Position, Collectible> collectibles,
  })  : arrows = List.unmodifiable(arrows),
        walls = Set.unmodifiable(walls),
        collectibles = Map.unmodifiable(collectibles),
        _occupancy = Map.unmodifiable(_computeOccupancy(arrows, walls)),
        _arrowById =
            Map.unmodifiable({for (final a in arrows) a.id: a});

  static Map<Position, String> _computeOccupancy(
    List<ArrowPath> arrows,
    Set<Position> walls,
  ) {
    final map = <Position, String>{};
    for (final wall in walls) {
      map[wall] = _wallOwner;
    }
    for (final arrow in arrows) {
      for (final cell in arrow.cells) {
        map[cell] = arrow.id;
      }
    }
    return map;
  }

  /// True if [position] falls inside the grid bounds.
  bool contains(Position position) =>
      position.row >= 0 &&
      position.row < rows &&
      position.col >= 0 &&
      position.col < cols;

  /// The arrow-path occupying [position], or null if the position is
  /// empty, out of bounds, or holds a wall.
  ArrowPath? arrowAt(Position position) {
    final owner = _occupancy[position];
    if (owner == null || owner == _wallOwner) return null;
    return _arrowById[owner];
  }

  /// True if [position] holds a wall.
  bool isWall(Position position) => _occupancy[position] == _wallOwner;

  /// The collectible sitting on [position], or null if there is none.
  /// Collectibles sit on otherwise-empty cells; they never coexist with
  /// arrows or walls.
  Collectible? collectibleAt(Position position) => collectibles[position];

  /// True if [position] is inside the grid and holds neither an arrow
  /// nor a wall. Used by the ray tracer (sub-block 4.4) to walk from an
  /// arrow's head toward the edge. Collectibles do not occupy in this
  /// sense — a ray passes through them.
  bool isEmpty(Position position) =>
      contains(position) && !_occupancy.containsKey(position);
}