import 'package:flutter/material.dart';

import '../../domain/models/cell.dart';

/// CellWidget — draws a single board cell as a colored square.
///
/// It switches on the cell's concrete type to pick a color and glyph.
/// This is presentation logic (how a cell looks), deliberately kept out
/// of the domain Cell classes (what a cell IS) — the domain stays free
/// of Flutter.
class CellWidget extends StatelessWidget {
  final Cell cell;

  const CellWidget({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor(),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Text(
          _glyph(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _backgroundColor() {
    final c = cell;
    if (c is WallCell) return Colors.blueGrey.shade700;
    if (c is StartCell) return Colors.green.shade600;
    if (c is ExitCell) return Colors.red.shade600;
    if (c is ArrowCell) return Colors.deepPurple.shade400;
    return Colors.grey.shade200; // EmptyCell
  }

  String _glyph() {
    final c = cell;
    if (c is StartCell) return 'S';
    if (c is ExitCell) return 'E';
    if (c is ArrowCell) return c.direction.symbol;
    return ''; // empty and wall show nothing
  }
}