import 'package:flutter/material.dart';

import '../../domain/models/cell.dart';

/// CellWidget — draws a single board cell.
///
/// Arrows are shown as colored tiles with a direction glyph; empty space
/// is a plain light tile. An optional [highlight] tints the tile to give
/// feedback (e.g. red when the player taps a blocked arrow).
class CellWidget extends StatelessWidget {
  final Cell cell;
  final Color? highlight;

  const CellWidget({super.key, required this.cell, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ?? _backgroundColor(),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Text(
          _glyph(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _backgroundColor() {
    if (cell is ArrowCell) return Colors.deepPurple.shade400;
    return Colors.grey.shade200; // empty space
  }

  String _glyph() {
    final c = cell;
    if (c is ArrowCell) return c.direction.symbol;
    return '';
  }
}
