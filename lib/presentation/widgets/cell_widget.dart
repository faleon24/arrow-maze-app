import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/arrow_path.dart';
import '../../domain/models/collectible.dart';

/// CellWidget — draws one board tile with a neon look via CustomPainter.
///
/// Handles four mutually exclusive contents:
/// - **Wall**: dark inner block, cyan neon border, outer glow
/// - **Arrow segment**: filled disc in the arrow's color with an outer
///   glow; the head cell also draws a large direction glyph
/// - **Collectible (STAR)**: yellow five-point star with outer glow
/// - **Empty**: deep-space background with a subtle grid outline
///
/// [highlight] tints the tile with an overlay on top of everything —
/// used to flash red on a blocked tap. The painter is stateless; a
/// change in any input triggers a repaint of this cell only.
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
    return CustomPaint(
      painter: _CellPainter(
        arrow: arrow,
        isWall: isWall,
        collectible: collectible,
        isArrowHead: isArrowHead,
        highlight: highlight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CellPainter extends CustomPainter {
  final ArrowPath? arrow;
  final bool isWall;
  final Collectible? collectible;
  final bool isArrowHead;
  final Color? highlight;

  // Deep-space background so neon pops.
  static const Color _background = Color(0xFF07091A);
  // Subtle indigo hairline between tiles so the grid stays readable.
  static const Color _gridLine = Color(0xFF1A2540);
  // Wall visual palette — a cool cyan glow.
  static const Color _wallGlow = Color(0xFF00E0FF);
  static const Color _wallFill = Color(0xFF0F2B44);
  // Collectible color matches the STAR yellow so pickups pop against
  // any arrow color they cross.
  static const Color _starColor = Color(0xFFFFEE00);

  const _CellPainter({
    this.arrow,
    this.isWall = false,
    this.collectible,
    this.isArrowHead = false,
    this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Background.
    canvas.drawRect(rect, Paint()..color = _background);

    // Grid outline.
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = _gridLine,
    );

    // Content — mutually exclusive.
    if (isWall) {
      _drawWall(canvas, size);
    } else if (arrow != null) {
      _drawArrowSegment(canvas, size);
    } else if (collectible?.kind == 'STAR') {
      _drawStar(canvas, size);
    }

    // Blocked flash sits on top so it's visible over any content.
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

    // Outer glow.
    canvas.drawRect(
      r,
      Paint()
        ..color = _wallGlow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Solid inner.
    canvas.drawRect(r, Paint()..color = _wallFill);
    // Neon border.
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _wallGlow,
    );
  }

  void _drawArrowSegment(Canvas canvas, Size size) {
    final color = arrow!.color.hex;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.32;

    // Outer glow — larger, blurred, translucent.
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Solid disc.
    canvas.drawCircle(center, radius, Paint()..color = color);

    // Head glyph.
    if (isArrowHead) {
      final tp = TextPainter(
        text: TextSpan(
          text: arrow!.direction.symbol,
          style: TextStyle(
            fontSize: size.shortestSide * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        center - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  void _drawStar(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide * 0.32;
    final innerR = outerR * 0.42;

    // Build a 5-point star as a Path alternating outer and inner radii.
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

    // Outer glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = _starColor.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Solid fill.
    canvas.drawPath(path, Paint()..color = _starColor);
  }

  @override
  bool shouldRepaint(covariant _CellPainter old) {
    return old.arrow?.id != arrow?.id ||
        old.isWall != isWall ||
        old.collectible?.position != collectible?.position ||
        old.isArrowHead != isArrowHead ||
        old.highlight != highlight;
  }
}