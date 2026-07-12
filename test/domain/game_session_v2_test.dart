import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/arrow_color.dart';
import 'package:arrow_maze_app/domain/models/arrow_path.dart';
import 'package:arrow_maze_app/domain/models/board_v2.dart';
import 'package:arrow_maze_app/domain/models/collectible.dart';
import 'package:arrow_maze_app/domain/models/direction.dart';
import 'package:arrow_maze_app/domain/models/game_session_v2.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

/// A 1-cell right-pointing arrow — the degenerate case that mirrors v1
/// arrow-cells. Used by most tests to keep the fixture cheap.
ArrowPath _rightSingle(String id, Position position) => ArrowPath(
      id: id,
      color: PinkColor(),
      cells: [position],
      direction: RightDirection(),
    );

void main() {
  group('GameSession.isActivatable', () {
    test('should_be_true_when_ray_from_single_cell_arrow_reaches_edge', () {
      final board = Board(
        rows: 1,
        cols: 3,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable('a1'), isTrue);
    });

    test('should_be_false_when_wall_blocks_the_ray', () {
      final board = Board(
        rows: 1,
        cols: 3,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {Position(0, 2)},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable('a1'), isFalse);
    });

    test('should_be_false_when_foreign_arrow_blocks_the_ray', () {
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [
          _rightSingle('a1', Position(0, 0)),
          _rightSingle('a2', Position(0, 2)),
        ],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable('a1'), isFalse);
      expect(session.isActivatable('a2'), isTrue);
    });

    test('should_be_activatable_when_multi_cell_path_head_ray_is_clear', () {
      // 3-cell right arrow; head at (0,2), ray to (0,3)-edge is empty.
      final path = ArrowPath(
        id: 'a1',
        color: GreenColor(),
        cells: [Position(0, 0), Position(0, 1), Position(0, 2)],
        direction: RightDirection(),
      );
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [path],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable('a1'), isTrue);
    });

    test('should_be_false_when_arrow_id_is_unknown', () {
      final board = Board(
        rows: 1,
        cols: 3,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable('ghost'), isFalse);
    });
  });

  group('GameSession.tap', () {
    test('should_return_not_an_arrow_when_position_has_no_arrow', () {
      final board = Board(
        rows: 2,
        cols: 2,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      final outcome = session.tap(Position(1, 1));

      expect(outcome, TapOutcome.notAnArrow);
      expect(session.movesUsed, 0);
      expect(session.lives, 3);
    });

    test('should_clear_arrow_and_count_a_move_when_ray_is_clear', () {
      final board = Board(
        rows: 1,
        cols: 2,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      final outcome = session.tap(Position(0, 0));

      expect(outcome, TapOutcome.cleared);
      expect(session.movesUsed, 1);
      expect(session.arrowsRemaining, 0);
    });

    test('should_clear_multi_cell_arrow_when_tail_cell_is_tapped', () {
      // Tap the tail — the whole path vacates.
      final path = ArrowPath(
        id: 'a1',
        color: BlueColor(),
        cells: [Position(0, 0), Position(0, 1)],
        direction: RightDirection(),
      );
      final board = Board(
        rows: 1,
        cols: 3,
        arrows: [path],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      final outcome = session.tap(Position(0, 0));

      expect(outcome, TapOutcome.cleared);
      expect(session.arrowsRemaining, 0);
      expect(session.board.arrowAt(Position(0, 0)), isNull);
      expect(session.board.arrowAt(Position(0, 1)), isNull);
    });

    test('should_cost_a_life_and_a_move_when_ray_is_blocked', () {
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [
          _rightSingle('a1', Position(0, 0)),
          _rightSingle('a2', Position(0, 2)),
        ],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10, maxLives: 3);

      final outcome = session.tap(Position(0, 0));

      expect(outcome, TapOutcome.blocked);
      expect(session.movesUsed, 1);
      expect(session.lives, 2);
      expect(session.arrowsRemaining, 2);
    });

    test('should_gather_collectibles_along_ray_when_arrow_is_cleared', () {
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {
          Position(0, 2): Collectible(position: Position(0, 2), kind: 'STAR'),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      final outcome = session.tap(Position(0, 0));

      expect(outcome, TapOutcome.cleared);
      expect(session.collectedPositions.contains(Position(0, 2)), isTrue);
      expect(session.board.collectibleAt(Position(0, 2)), isNull);
    });
  });

  group('GameSession chains', () {
    test('should_unblock_neighbour_when_blocking_arrow_is_cleared', () {
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [
          _rightSingle('a1', Position(0, 0)),
          _rightSingle('a2', Position(0, 2)),
        ],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      session.tap(Position(0, 2)); // clear the front arrow first
      final outcome = session.tap(Position(0, 0)); // now unblocked

      expect(outcome, TapOutcome.cleared);
      expect(session.isCleared, isTrue);
    });
  });

  group('GameSession win/lose', () {
    test('should_be_cleared_when_no_arrows_remain', () {
      final board = Board(
        rows: 1,
        cols: 2,
        arrows: [_rightSingle('a1', Position(0, 0))],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10);

      session.tap(Position(0, 0));

      expect(session.isCleared, isTrue);
      expect(session.isFailed, isFalse);
    });

    test('should_fail_when_lives_run_out_with_arrows_remaining', () {
      final board = Board(
        rows: 1,
        cols: 4,
        arrows: [
          _rightSingle('a1', Position(0, 0)),
          _rightSingle('a2', Position(0, 2)),
        ],
        walls: {},
        collectibles: {},
      );
      final session = GameSession(board: board, moveLimit: 10, maxLives: 1);

      session.tap(Position(0, 0)); // blocked -> loses only life

      expect(session.lives, 0);
      expect(session.isFailed, isTrue);
    });
  });
}