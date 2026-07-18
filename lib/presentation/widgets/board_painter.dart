import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/arrow_path.dart';
import '../../domain/models/board.dart';
import '../../domain/models/position.dart';
import 'hex_layout.dart';

/// BoardPainter — draws ONLY the arrows (plus walls, collectibles and the
/// tap-feedback highlight). The hex cells themselves are not drawn, so the
/// arrows read as free-floating shapes on the dark background and nothing
/// "erodes" as the board is cleared. Tap hit-testing is geometric
/// (HexLayout.cellAt), so hiding the cells does not affect input.
class BoardPainter extends CustomPainter {
  final Board board;
  final Map<Position, Color> highlights;

  BoardPainter({required this.board, this.highlights = const {}});

  static const Color _wallGlow = Color(0xFF00E0FF);
  static const Color _wallFill = Color(0xFF0F2B44);
  static const Color _starColor = Color(0xFFFFEE00);

  @override
  void paint(Canvas canvas, Size size) {
    final layout = HexLayout(size, board.rows, board.cols);

    for (var row = 0; row < board.rows; row++) {
      for (var col = 0; col < board.cols; col++) {
        final pos = Position(row, col);
        final c = layout.center(row, col);
        final hex = layout.hexPath(c);
        if (board.isWall(pos)) _drawWall(canvas, hex);
        if (board.collectibleAt(pos)?.kind == 'STAR') {
          _drawStar(canvas, c, layout.h * 0.20);
        }
        final hl = highlights[pos];
        if (hl != null) {
          canvas.drawPath(hex, Paint()..color = hl.withValues(alpha: 0.35));
        }
      }
    }
    for (final arrow in board.arrows) {
      _paintArrow(canvas, arrow, layout);
    }
  }

  void _drawWall(Canvas canvas, Path hex) {
    canvas.drawPath(
      hex,
      Paint()
        ..color = _wallGlow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(hex, Paint()..color = _wallFill);
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _wallGlow,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double outerR) {
    final innerR = outerR * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = _starColor.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, Paint()..color = _starColor);
  }

  void _paintArrow(Canvas canvas, ArrowPath arrow, HexLayout layout) {
    final color = arrow.color.hex;
    final tile = layout.h;
    final strokeWidth = tile * 0.08;
    final centers = arrow.cells.map(layout.centerOf).toList();
    final headCenter = layout.centerOf(arrow.head);

    final neighbour = layout.centerOf(arrow.direction.apply(arrow.head));
    var fwd = neighbour - headCenter;
    final dist = fwd.distance;
    fwd = dist > 0 ? fwd / dist : const Offset(1, 0);

    final arrowheadBase = headCenter + fwd * (tile * 0.15);
    final body = Path();
    if (centers.length == 1) {
      final stubStart = headCenter - fwd * (tile * 0.25);
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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final side = Offset(-fwd.dy, fwd.dx);
    final tip = headCenter + fwd * (tile * 0.42);
    final base1 = headCenter + fwd * (tile * 0.15) + side * (tile * 0.16);
    final base2 = headCenter + fwd * (tile * 0.15) - side * (tile * 0.16);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
