import 'package:flutter/material.dart';
import '../../domain/models/arrow_path.dart';
import '../../domain/models/board.dart';
import '../../domain/models/direction.dart';
import '../../domain/models/position.dart';


class BoardPainter extends CustomPainter {
  final Board board;
  BoardPainter({required this.board});
  @override
  void paint(Canvas canvas, Size size) {
    if (board.arrows.isEmpty) return;
    final tileWidth = size.width / board.cols;
    final tileHeight = size.height / board.rows;
    // v2 boards render on a square grid via AspectRatio, so
    // tileWidth ≈ tileHeight. Min prevents overshoot on non-square rects.
    final tile = tileWidth < tileHeight ? tileWidth : tileHeight;
    final strokeWidth = tile * 0.08;
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
    final headCenter = _cellCenter(arrow.head, tileWidth, tileHeight);
    final delta = _directionVector(arrow.direction);
    final fwd = Offset(delta.dx * tile, delta.dy * tile);
    // Where the arrowhead's base sits — the body line ends exactly here
    // so head and body meet seamlessly with no visible gap.
    final arrowheadBase = headCenter + fwd * 0.15;
    final body = Path();
    if (centers.length == 1) {
      // Single-cell arrow: draw a short stub behind the arrowhead so it
      // reads as "arrow with a small tail" instead of a floating triangle.
      final stubStart = headCenter - fwd * 0.25;
      body.moveTo(stubStart.dx, stubStart.dy);
      body.lineTo(arrowheadBase.dx, arrowheadBase.dy);
    } else {
      body.moveTo(centers.first.dx, centers.first.dy);
      for (var i = 1; i < centers.length; i++) {
        body.lineTo(centers[i].dx, centers[i].dy);
      }
      body.lineTo(arrowheadBase.dx, arrowheadBase.dy);
    }
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 2.0
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
    final fwd = Offset(delta.dx * tile, delta.dy * tile);
    final side = Offset(-fwd.dy, fwd.dx);
    // Small sharp triangle — reads as a directional pointer without
    // eating the visual space of the body line.
    final tip = headCenter + fwd * 0.42;
    final base1 = headCenter + fwd * 0.15 + side * 0.16;
    final base2 = headCenter + fwd * 0.15 - side * 0.16;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }
  Offset _cellCenter(Position p, double tileWidth, double tileHeight) {
    return Offset(
      (p.col + 0.5) * tileWidth,
      (p.row + 0.5) * tileHeight,
    );
  }
  Offset _directionVector(Direction dir) {
    final step = dir.apply(Position(0, 0));
    return Offset(step.col.toDouble(), step.row.toDouble());
  }
  @override
  bool shouldRepaint(covariant BoardPainter old) {
    return !identical(old.board, board);
  }
}