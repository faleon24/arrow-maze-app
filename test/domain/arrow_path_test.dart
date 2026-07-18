import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/arrow_color.dart';
import 'package:arrow_maze_app/domain/models/arrow_path.dart';
import 'package:arrow_maze_app/domain/models/direction.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

void main() {
  group('ArrowPath', () {
    test('should_expose_last_cell_as_head_when_path_has_multiple_cells', () {
      final path = ArrowPath(
        id: 'a1',
        color: PinkColor(),
        cells: [Position(0, 0), Position(0, 1), Position(0, 2)],
        direction: EastDirection(),
      );

      expect(path.head, Position(0, 2));
      expect(path.cells.length, 3);
    });

    test('should_treat_single_cell_as_degenerate_head_when_path_has_one_cell', () {
      final path = ArrowPath(
        id: 'a2',
        color: BlueColor(),
        cells: [Position(1, 1)],
        direction: NorthEastDirection(),
      );

      expect(path.head, Position(1, 1));
    });

    test('should_reject_empty_cells_when_constructed', () {
      expect(
        () => ArrowPath(
          id: 'a3',
          color: GreenColor(),
          cells: const [],
          direction: SouthEastDirection(),
        ),
        throwsArgumentError,
      );
    });

    test('should_expose_unmodifiable_cells_when_constructed', () {
      final path = ArrowPath(
        id: 'a4',
        color: PurpleColor(),
        cells: [Position(0, 0)],
        direction: WestDirection(),
      );

      expect(() => path.cells.add(Position(0, 1)), throwsUnsupportedError);
    });

    test('should_be_equal_when_all_fields_match', () {
      final a = ArrowPath(
        id: 'a5',
        color: YellowColor(),
        cells: [Position(0, 0), Position(1, 0)],
        direction: SouthEastDirection(),
      );
      final b = ArrowPath(
        id: 'a5',
        color: YellowColor(),
        cells: [Position(0, 0), Position(1, 0)],
        direction: SouthEastDirection(),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}