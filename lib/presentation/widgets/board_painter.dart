import 'package:flutter/material.dart';
import '../../domain/models/arrow_path.dart';
import '../../domain/models/board.dart';
import '../../domain/models/direction.dart';
import '../../domain/models/position.dart';
/// BoardPainter — renders every arrow-path on a v2 [Board] as a single
/// continuous neon line with a filled arrowhead at the head.
///
/// Runs as an overlay above the grid of [CellWidget]s: walls and
/// collectibles are drawn per-tile below; every arrow spans multiple
/// tiles here, so it must be drawn once against the whole board rather
/// than cell-by-cell — the reference "serpenteante" look comes from a
/// path that turns with rounded joins, not from independent discs.
///
/// StrokeJoin.round + StrokeCap.round make each turn read as a smooth
/// curve without explicit bezier math; a mask-blur underlay gives the
/// neon glow. The arrowhead is a filled triangle oriented by the
/// direction vector derived from Direction.apply(Position(0,0)).
///
/// Stateless painter: given the same board, produces the same image.
/// Repaints only when the board identity changes.
class BoardPainter extends CustomPainter {
  final Board board;
  BoardPainter({required this.board});
  @override
  void paint(Canvas canvas, Size size) {
    if (board.arrows.isEmpty) return;
    final tileWidth = size.width / board.cols;
    final tileHeight = size.height / board.rows;
    // v2 boards render on a square grid via AspectRatio, so
    // tileWidth ≈ tileHeight. The min avoids overshoot if the parent
    // ever constrains us to a non-square rect.
    final tile = tileWidth < tileHeight ? tileWidth : tileHeight;
    final strokeWidth = tile * 0.5;
    for (final arrow in board.arrows) {
      _paintArrow(canvas, arrow, tile, tileWidth, tileHeight, strokeWidth);
    }
  }
  void _paintArrow(
    Canvas canvas,
    ArrowPath arrow,
    double tile,
    double tileWidth,
    double tileHeight,
    double strokeWidth,
  ) {
    final color = arrow.color.hex;
    final centers = arrow.cells
        .map((p) => _cellCenter(p, tileWidth, tileHeight))
        .toList();
    if (centers.isEmpty) return;
    // Body path — line segments joined with rounded joins so each turn
    // reads as a smooth curve.
    final body = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      body.lineTo(centers[i].dx, centers[i].dy);
    }
    // Glow underlay.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Solid stroke.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    _paintArrowhead(canvas, arrow, tile, tileWidth, tileHeight, color);
  }
  void _paintArrowhead(
    Canvas canvas,
    ArrowPath arrow,
    double tile,
    double tileWidth,
    double tileHeight,
    Color color,
  ) {
    final headCenter = _cellCenter(arrow.head, tileWidth, tileHeight);
    final delta = _directionVector(arrow.direction);
    // Local orthonormal basis: forward = delta * tile, side = 90° rotation.
    final fwd = Offset(delta.dx * tile, delta.dy * tile);
    final side = Offset(-fwd.dy, fwd.dx);
    // Filled triangle: tip ahead, base symmetric behind.
    final tip = headCenter + fwd * 0.4;
    final base1 = headCenter - fwd * 0.05 + side * 0.25;
    final base2 = headCenter - fwd * 0.05 - side * 0.25;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(head, Paint()..color = color);
  }
  Offset _cellCenter(Position p, double tileWidth, double tileHeight) {
    return Offset(
      (p.col + 0.5) * tileWidth,
      (p.row + 0.5) * tileHeight,
    );
  }
  Offset _directionVector(Direction dir) {
    // Direction.apply(0,0) yields the (dr, dc) unit step.
    // Canvas: x = col, y = row.
    final step = dir.apply(Position(0, 0));
    return Offset(step.col.toDouble(), step.row.toDouble());
  }
  @override
  bool shouldRepaint(covariant BoardPainter old) {
    return !identical(old.board, board);
  }
}