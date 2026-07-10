import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_maze_app/domain/models/board.dart';
import 'package:arrow_maze_app/domain/models/cell.dart';
import 'package:arrow_maze_app/domain/models/direction.dart';
import 'package:arrow_maze_app/domain/models/game_session.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

/// Builds a board from a compact map of position -> cell, filling the
/// grid dimensions given. Only the listed cells exist; the rest is empty.
Board buildBoard({
  required int rows,
  required int cols,
  required Map<Position, Cell> cells,
}) {
  return Board(rows: rows, cols: cols, cells: cells);
}

void main() {
  group('GameSession.isActivatable', () {
    test('an arrow with a clear ray to the edge is activatable', () {
      // A single right-pointing arrow at 0,0 on a 1x3 board: its ray
      // (0,1 -> 0,2 -> edge) is empty, so it can escape.
      final board = buildBoard(
        rows: 1,
        cols: 3,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable(const Position(0, 0)), isTrue);
    });

    test('an arrow blocked by another arrow in its ray is not activatable', () {
      // Two right-pointing arrows: the one at 0,0 is blocked by the one
      // at 0,2 sitting in its exit ray.
      final board = buildBoard(
        rows: 1,
        cols: 4,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
          const Position(0, 2): ArrowCell(const Position(0, 2), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable(const Position(0, 0)), isFalse);
    });

    test('the unblocked arrow in a blocked pair is activatable', () {
      // Same pair: the arrow at 0,2 points right into a clear edge, so it
      // escapes even though it blocks the other one.
      final board = buildBoard(
        rows: 1,
        cols: 4,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
          const Position(0, 2): ArrowCell(const Position(0, 2), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable(const Position(0, 2)), isTrue);
    });

    test('a non-arrow cell is never activatable', () {
      final board = buildBoard(rows: 2, cols: 2, cells: {});
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable(const Position(0, 0)), isFalse);
    });

    test('an arrow pointing straight at the edge is activatable', () {
      // A down-pointing arrow on the bottom row escapes immediately: its
      // next step is already off the board. This is the simplest "points
      // outward" case the rules describe.
      final board = buildBoard(
        rows: 2,
        cols: 1,
        cells: {
          const Position(1, 0): ArrowCell(const Position(1, 0), DownDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      expect(session.isActivatable(const Position(1, 0)), isTrue);
    });
  });

  group('GameSession.tap', () {
    test('tapping an activatable arrow clears it and counts a move', () {
      final board = buildBoard(
        rows: 1,
        cols: 2,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      final outcome = session.tap(const Position(0, 0));

      expect(outcome, TapOutcome.cleared);
      expect(session.movesUsed, 1);
      expect(session.arrowsRemaining, 0);
    });

    test('tapping a blocked arrow costs a move and a life', () {
      final board = buildBoard(
        rows: 1,
        cols: 4,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
          const Position(0, 2): ArrowCell(const Position(0, 2), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10, maxLives: 3);

      final outcome = session.tap(const Position(0, 0));

      expect(outcome, TapOutcome.blocked);
      expect(session.movesUsed, 1);
      expect(session.lives, 2);
      expect(session.arrowsRemaining, 2); // nothing removed
    });

    test('clearing a blocking arrow unblocks its neighbour (chain)', () {
      // Clear the front arrow first, then the previously-blocked one.
      final board = buildBoard(
        rows: 1,
        cols: 4,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
          const Position(0, 2): ArrowCell(const Position(0, 2), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      session.tap(const Position(0, 2)); // clear the front one
      final outcome = session.tap(const Position(0, 0)); // now unblocked

      expect(outcome, TapOutcome.cleared);
      expect(session.isCleared, isTrue);
    });
  });

  group('GameSession win/lose', () {
    test('the session is cleared when no arrows remain', () {
      final board = buildBoard(
        rows: 1,
        cols: 2,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10);

      session.tap(const Position(0, 0));

      expect(session.isCleared, isTrue);
      expect(session.isFailed, isFalse);
    });

    test('the session fails when lives run out with arrows remaining', () {
      final board = buildBoard(
        rows: 1,
        cols: 4,
        cells: {
          const Position(0, 0): ArrowCell(const Position(0, 0), RightDirection()),
          const Position(0, 2): ArrowCell(const Position(0, 2), RightDirection()),
        },
      );
      final session = GameSession(board: board, moveLimit: 10, maxLives: 1);

      session.tap(const Position(0, 0)); // blocked -> loses the only life

      expect(session.lives, 0);
      expect(session.isFailed, isTrue);
    });
  });
}