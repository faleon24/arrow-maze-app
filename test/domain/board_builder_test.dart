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
      direction: RightDirection(),
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
    test('should_reject_arrow_when_cells_are_not_contiguous_in_direction', () {
      final gap = _rightPath('a1', [Position(0, 0), Position(0, 2)]);

      expect(
        () => BoardBuilder().withDimensions(3, 3).addArrow(gap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_reject_arrow_when_cells_dont_align_with_direction', () {
      // direction RIGHT but cells step DOWN.
      final wrongAxis = ArrowPath(
        id: 'a1',
        color: GreenColor(),
        cells: [Position(0, 0), Position(1, 0)],
        direction: RightDirection(),
      );

      expect(
        () => BoardBuilder().withDimensions(3, 3).addArrow(wrongAxis),
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
            'direction': 'RIGHT',
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