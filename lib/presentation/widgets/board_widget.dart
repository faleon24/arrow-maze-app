import 'package:flutter/material.dart';

import '../../domain/models/board.dart';
import '../../domain/models/position.dart';
import 'cell_widget.dart';

/// BoardWidget — draws the full grid of a Board as rows x cols squares.
///
/// Uses GridView to lay out cells. It asks the Board for the cell at each
/// position (which returns an EmptyCell for gaps), so the widget never
/// needs to know how the board stores its cells.
class BoardWidget extends StatelessWidget {
  final Board board;

  const BoardWidget({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      // Keep the grid square-ish based on its dimensions.
      aspectRatio: board.cols / board.rows,
      child: GridView.builder(
        // Don't scroll; the whole board fits on screen.
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: board.cols,
        ),
        itemCount: board.rows * board.cols,
        itemBuilder: (context, i) {
          // Turn the flat index into a row/col position.
          final row = i ~/ board.cols;
          final col = i % board.cols;
          final cell = board.cellAt(Position(row, col));
          return CellWidget(cell: cell);
        },
      ),
    );
  }
}