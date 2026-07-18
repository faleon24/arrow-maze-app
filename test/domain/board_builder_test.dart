import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/arrow_color.dart';
import 'package:arrow_maze_app/domain/models/arrow_path.dart';
import 'package:arrow_maze_app/domain/models/board_builder.dart';
import 'package:arrow_maze_app/domain/models/collectible.dart';
import 'package:arrow_maze_app/domain/models/direction.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

ArrowPath _rightPath(String id, List<Position> cells) => ArrowPath(
      id: id,
      color: PinkColor(),
      cells: cells,
      direction: EastDirection(),
    );

void main() {
  group('BoardBuilder.build', () {
    test('should_build_empty_board_when_only_dimensions_are_set', () {
      final board = BoardBuilder().withDimensions(3, 3).build();

      expect(board.rows, 3);
      expect(board.cols, 3);
      expect(board.arrows, isEmpty);
      expect(board.walls, isEmpty);
      expect(board.collectibles, isEmpty);
    });

    test('should_build_board_with_arrow_wall_and_collectible_when_added', () {
      final board = BoardBuilder()
          .withDimensions(3, 3)
          .addArrow(_rightPath('a1', [Position(0, 0), Position(0, 1)]))
          .addWall(Position(1, 1))
          .addCollectible(
            Collectible(position: Position(2, 2), kind: 'STAR'),
          )
          .build();

      expect(board.arrows.single.id, 'a1');
      expect(board.walls.contains(Position(1, 1)), isTrue);
      expect(board.collectibleAt(Position(2, 2))?.kind, 'STAR');
    });

    test('should_throw_state_error_when_build_called_before_dimensions', () {
      expect(() => BoardBuilder().build(), throwsStateError);
    });
  });

  group('BoardBuilder.addArrow invariants', () {
    test('should_reject_arrow_when_cells_have_a_gap', () {
      final gap = _rightPath('a1', [Position(0, 0), Position(0, 2)]);

      expect(
        () => BoardBuilder().withDimensions(3, 3).addArrow(gap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_reject_arrow_when_id_duplicates_existing_arrow', () {
      final builder = BoardBuilder()
          .withDimensions(3, 3)
          .addArrow(_rightPath('dup', [Position(0, 0)]));

      expect(
        () => builder.addArrow(_rightPath('dup', [Position(2, 0)])),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_reject_arrow_when_cell_overlaps_wall', () {
      final builder = BoardBuilder()
          .withDimensions(3, 3)
          .addWall(Position(0, 1));

      expect(
        () => builder.addArrow(_rightPath('a1', [Position(0, 1)])),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_reject_arrow_when_cell_falls_out_of_bounds', () {
      expect(
        () => BoardBuilder()
            .withDimensions(2, 2)
            .addArrow(_rightPath('a1', [Position(0, 0), Position(0, 1), Position(0, 2)])),
        throwsA(isA<FormatException>()),
      );
    });

    group('BoardBuilder.addArrow accepts bent paths', () {
    test('should_accept_arrow_when_cells_form_an_l_shape', () {
      final l = ArrowPath(
        id: 'L1',
        color: GreenColor(),
        cells: [
          Position(2, 0),
          Position(2, 1),
          Position(2, 2),
          Position(1, 2),
        ],
        direction: NorthEastDirection(),
      );
      final board = BoardBuilder().withDimensions(5, 5).addArrow(l).build();
      expect(board.arrows.single.cells.length, 4);
      expect(board.arrows.single.head, Position(1, 2));
    });
    test('should_accept_arrow_when_cells_form_a_u_shape', () {
      final u = ArrowPath(
        id: 'U1',
        color: BlueColor(),
        cells: [
          Position(0, 0),
          Position(1, 0),
          Position(2, 0),
          Position(2, 1),
          Position(2, 2),
          Position(1, 2),
          Position(0, 2),
        ],
        direction: NorthEastDirection(),
      );
      final board = BoardBuilder().withDimensions(5, 5).addArrow(u).build();
      expect(board.arrows.single.cells.length, 7);
      expect(board.arrows.single.head, Position(0, 2));
    });
    test('should_accept_arrow_when_cells_form_an_s_shape', () {
      final s = ArrowPath(
        id: 'S1',
        color: PurpleColor(),
        cells: [
          Position(0, 0),
          Position(0, 1),
          Position(1, 1),
          Position(1, 2),
          Position(2, 2),
        ],
        direction: SouthEastDirection(),
      );
      final board = BoardBuilder().withDimensions(5, 5).addArrow(s).build();
      expect(board.arrows.single.cells.length, 5);
      expect(board.arrows.single.head, Position(2, 2));
    });
  });


  });

  group('BoardBuilder.addWall / addCollectible invariants', () {
    test('should_reject_wall_when_position_overlaps_arrow', () {
      final builder = BoardBuilder()
          .withDimensions(3, 3)
          .addArrow(_rightPath('a1', [Position(1, 1)]));

      expect(
        () => builder.addWall(Position(1, 1)),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_reject_collectible_when_position_overlaps_wall', () {
      final builder = BoardBuilder()
          .withDimensions(3, 3)
          .addWall(Position(2, 2));

      expect(
        () => builder.addCollectible(
          Collectible(position: Position(2, 2), kind: 'STAR'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('BoardBuilder.fromJson', () {
    test('should_parse_board_json_when_shape_is_valid', () {
      final json = {
        'version': 2,
        'rows': 3,
        'cols': 3,
        'arrows': [
          {
            'id': 'a1',
            'color': 'PINK',
            'direction': 'E',
            'cells': ['0,0', '0,1'],
          },
        ],
        'walls': ['1,1'],
        'collectibles': [
          {'position': '2,2', 'kind': 'STAR'},
        ],
      };

      final board = BoardBuilder.fromJson(json);

      expect(board.rows, 3);
      expect(board.arrows.single.id, 'a1');
      expect(board.arrows.single.color.name, 'PINK');
      expect(board.walls.contains(Position(1, 1)), isTrue);
      expect(board.collectibleAt(Position(2, 2))?.kind, 'STAR');
    });

    test('should_reject_json_when_version_is_not_two', () {
      final json = {
        'version': 1,
        'rows': 2,
        'cols': 2,
        'arrows': [],
        'walls': [],
        'collectibles': [],
      };

      expect(
        () => BoardBuilder.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}