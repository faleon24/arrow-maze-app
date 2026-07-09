import 'cell.dart';
import 'cell_factory.dart';
import 'position.dart';

/// Board — the playable grid of a level (the UML's `Board <Composite>`).

///
/// Holds every cell keyed by position for O(1) lookup, plus the grid
/// dimensions. Built from the backend's flat cell list via the
/// CellFactory, which turns each raw snapshot into a polymorphic Cell.
class Board {
  final int rows;
  final int cols;
  final Map<Position, Cell> cells;

  const Board({
    required this.rows,
    required this.cols,
    required this.cells,
  });

  /// Build a Board from the backend's board JSON:
  /// { "rows": 3, "cols": 3, "cells": [ {...}, {...} ] }.
  factory Board.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final rawCells = json['cells'] as List<dynamic>;

    final cells = <Position, Cell>{};
    for (final raw in rawCells) {
      final cell = CellFactory.fromJson(raw as Map<String, dynamic>);
      cells[cell.position] = cell;
    }

    return Board(rows: rows, cols: cols, cells: cells);
  }

  /// The cell at a position, or an EmptyCell if none was defined there.
  /// The backend only sends non-empty cells, so any gap in the grid is
  /// walkable empty space by default.
  Cell cellAt(Position position) {
    return cells[position] ?? EmptyCell(position);
  }
}