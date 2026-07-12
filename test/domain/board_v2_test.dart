import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/arrow_color.dart';
import 'package:arrow_maze_app/domain/models/arrow_path.dart';
import 'package:arrow_maze_app/domain/models/board_v2.dart';
import 'package:arrow_maze_app/domain/models/collectible.dart';
import 'package:arrow_maze_app/domain/models/direction.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

/// Small helper: a 3x3 board with one right-pointing 2-cell arrow at
/// (1,0)-(1,1), one wall at (0,0), one STAR at (2,2). Reused by several
/// tests to keep each case focused on one predicate.
Board _sampleBoard() {
  final arrow = ArrowPath(
    id: 'a1',
    color: PinkColor(),
    cells: [Position(1, 0), Position(1, 1)],
    direction: RightDirection(),
  );
  return Board(
    rows: 3,
    cols: 3,
    arrows: [arrow],
    walls: {Position(0, 0)},
    collectibles: {
      Position(2, 2): Collectible(position: Position(2, 2), kind: 'STAR'),
    },
  );
}

void main() {
  group('Board.contains', () {
    test('should_return_true_when_position_is_inside_grid_bounds', () {
      final board = _sampleBoard();
      expect(board.contains(Position(0, 0)), isTrue);
      expect(board.contains(Position(2, 2)), isTrue);
    });

    test('should_return_false_when_position_is_outside_grid_bounds', () {
      final board = _sampleBoard();
      expect(board.contains(Position(-1, 0)), isFalse);
      expect(board.contains(Position(3, 0)), isFalse);
      expect(board.contains(Position(0, 3)), isFalse);
    });
  });

  group('Board.arrowAt', () {
    test('should_return_the_arrow_when_position_holds_any_of_its_cells', () {
      final board = _sampleBoard();

      final head = board.arrowAt(Position(1, 1));
      final tail = board.arrowAt(Position(1, 0));

      expect(head, isNotNull);
      expect(head, tail); // both cells of the path resolve to same arrow
      expect(head!.id, 'a1');
    });

    test('should_return_null_when_position_is_a_wall', () {
      final board = _sampleBoard();
      expect(board.arrowAt(Position(0, 0)), isNull);
    });

    test('should_return_null_when_position_is_empty', () {
      final board = _sampleBoard();
      expect(board.arrowAt(Position(2, 0)), isNull);
    });
  });

  group('Board.isWall', () {
    test('should_return_true_when_position_holds_a_wall', () {
      final board = _sampleBoard();
      expect(board.isWall(Position(0, 0)), isTrue);
    });

    test('should_return_false_when_position_is_an_arrow_cell', () {
      final board = _sampleBoard();
      expect(board.isWall(Position(1, 0)), isFalse);
      expect(board.isWall(Position(1, 1)), isFalse);
    });

    test('should_return_false_when_position_is_empty_or_collectible', () {
      final board = _sampleBoard();
      expect(board.isWall(Position(2, 0)), isFalse); // empty
      expect(board.isWall(Position(2, 2)), isFalse); // collectible
    });
  });

  group('Board.collectibleAt', () {
    test('should_return_the_collectible_when_position_holds_one', () {
      final board = _sampleBoard();

      final c = board.collectibleAt(Position(2, 2));

      expect(c, isNotNull);
      expect(c!.kind, 'STAR');
    });

    test('should_return_null_when_position_has_no_collectible', () {
      final board = _sampleBoard();
      expect(board.collectibleAt(Position(0, 0)), isNull);
      expect(board.collectibleAt(Position(1, 0)), isNull);
    });
  });

  group('Board.isEmpty', () {
    test('should_return_true_when_position_is_in_bounds_and_unoccupied', () {
      final board = _sampleBoard();
      expect(board.isEmpty(Position(0, 1)), isTrue);
      expect(board.isEmpty(Position(2, 0)), isTrue);
    });

    test('should_treat_collectible_cells_as_empty_for_ray_tracing', () {
      // Collectibles do not block rays — the tracer walks through them.
      final board = _sampleBoard();
      expect(board.isEmpty(Position(2, 2)), isTrue);
    });

    test('should_return_false_when_position_is_wall_or_arrow_cell', () {
      final board = _sampleBoard();
      expect(board.isEmpty(Position(0, 0)), isFalse); // wall
      expect(board.isEmpty(Position(1, 0)), isFalse); // arrow
    });

    test('should_return_false_when_position_is_out_of_bounds', () {
      final board = _sampleBoard();
      expect(board.isEmpty(Position(-1, 0)), isFalse);
      expect(board.isEmpty(Position(0, 3)), isFalse);
    });
  });

  group('Board immutability', () {
    test('should_expose_unmodifiable_collections_when_constructed', () {
      final board = _sampleBoard();

      expect(
        () => board.arrows.add(
          ArrowPath(
            id: 'x',
            color: BlueColor(),
            cells: [Position(0, 1)],
            direction: UpDirection(),
          ),
        ),
        throwsUnsupportedError,
      );
      expect(() => board.walls.add(Position(2, 1)), throwsUnsupportedError);
      expect(
        () => board.collectibles[Position(0, 1)] = Collectible(
          position: Position(0, 1),
          kind: 'STAR',
        ),
        throwsUnsupportedError,
      );
    });
  });
}