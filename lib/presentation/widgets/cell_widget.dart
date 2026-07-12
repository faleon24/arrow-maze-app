import 'package:flutter/material.dart';

import '../../domain/models/arrow_path.dart';
import '../../domain/models/collectible.dart';

/// CellWidget — draws a single board tile in v2.
///
/// The tile inspects up to four things at its position:
/// - [arrow] the ArrowPath occupying it (null if none)
/// - [isArrowHead] whether this tile is the arrow's leading cell (only
///   the head shows the direction glyph)
/// - [isWall] whether the tile is impassable
/// - [collectible] a pickup (STAR for now) sitting on an otherwise-empty
///   tile
///
/// [highlight] optionally tints the tile — used to flash red on a
/// blocked tap. Container-based rendering is the placeholder; Fase 5.3
/// swaps it for a CustomPainter neon look.
class CellWidget extends StatelessWidget {
  final ArrowPath? arrow;
  final bool isWall;
  final Collectible? collectible;
  final bool isArrowHead;
  final Color? highlight;

  const CellWidget({
    super.key,
    this.arrow,
    this.isWall = false,
    this.collectible,
    this.isArrowHead = false,
    this.highlight,
  });

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
    if (isWall) return Colors.grey.shade800;
    if (arrow != null) return arrow!.color.hex;
    return Colors.grey.shade200;
  }

  String _glyph() {
    if (isWall) return '';
    if (isArrowHead) return arrow!.direction.symbol;
    if (collectible?.kind == 'STAR') return '★';
    return '';
  }
}