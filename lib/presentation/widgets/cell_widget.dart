import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/collectible.dart';
/// CellWidget — draws one board tile with a neon look via CustomPainter.
///
/// Handles three mutually exclusive contents:
/// - **Wall**: dark inner block, cyan neon border, outer glow
/// - **Collectible (STAR)**: yellow five-point star with outer glow
/// - **Empty**: deep-space background with a subtle grid outline
///
/// Arrows are NOT drawn here — [BoardPainter] renders them as continuous
/// polylines across multiple tiles, from a Stack overlay above the grid.
/// The split lets each arrow read as one serpenteante line instead of
/// a chain of independent discs (see §5.X.3 of the plan).
///
/// [highlight] tints the tile with an overlay on top of everything —
/// used to flash red on a blocked tap. Painter is stateless.
class CellWidget extends StatelessWidget {
  final bool isWall;
  final Collectible? collectible;
  final Color? highlight;
  const CellWidget({
    super.key,
    this.isWall = false,
    this.collectible,
    this.highlight,
  });
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CellPainter(
        isWall: isWall,
        collectible: collectible,
        highlight: highlight,
      ),
      child: const SizedBox.expand(),
    );
  }
}
class _CellPainter extends CustomPainter {
  final bool isWall;
  final Collectible? collectible;
  final Color? highlight;
  static const Color _background = Color(0xFF07091A);
  static const Color _gridLine = Color(0xFF1A2540);
  static const Color _wallGlow = Color(0xFF00E0FF);
  static const Color _wallFill = Color(0xFF0F2B44);
  static const Color _starColor = Color(0xFFFFEE00);
  const _CellPainter({
    this.isWall = false,
    this.collectible,
    this.highlight,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (isWall) {
      _drawWall(canvas, size);
    } else if (collectible?.kind == 'STAR') {
      _drawStar(canvas, size);
    }
    if (highlight != null) {
      canvas.drawRect(
        rect,
        Paint()..color = highlight!.withValues(alpha: 0.35),
      );
    }
  }
  void _drawWall(Canvas canvas, Size size) {
    final pad = size.shortestSide * 0.12;
    final r = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    canvas.drawRect(
      r,
      Paint()
        ..color = _wallGlow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(r, Paint()..color = _wallFill);
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _wallGlow,
    );
  }
  void _drawStar(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide * 0.32;
    final innerR = outerR * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
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
  @override
  bool shouldRepaint(covariant _CellPainter old) {
    return old.isWall != isWall ||
        old.collectible?.position != collectible?.position ||
        old.highlight != highlight;
  }
}