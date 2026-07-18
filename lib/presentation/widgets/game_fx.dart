import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/position.dart';
import 'hex_layout.dart';

/// How long a single "arrow cleared" effect lasts.
const Duration kClearFxDuration = Duration(milliseconds: 480);

/// One in-flight clear effect: a glow that flies from the arrow's head
/// along its ray to the board edge, a fading trail behind it, and a pop
/// for every star the ray collected on the way out. On a hex board the
/// ray zig-zags, so we keep the full [rayCells] path instead of a single
/// {dRow,dCol} delta.
class ClearFx {
  ClearFx({
    required this.head,
    required this.rayCells,
    required this.color,
    required this.stars,
  }) : start = DateTime.now();

  final Position head;
  final List<Position> rayCells;
  final Color color;
  final List<Position> stars;
  final DateTime start;

  double get progress {
    final ms = DateTime.now().difference(start).inMilliseconds;
    return (ms / kClearFxDuration.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// Draws all active [ClearFx] effects. Lives inside the same transformed
/// Stack as BoardPainter, so its coordinates line up with the board under
/// zoom/pan. Repaints every animation frame.
class ClearFxPainter extends CustomPainter {
  ClearFxPainter({required this.effects, required this.rows, required this.cols});

  final List<ClearFx> effects;
  final int rows;
  final int cols;

  @override
  void paint(Canvas canvas, Size size) {
    if (effects.isEmpty) return;
    final layout = HexLayout(size, rows, cols);
    final tile = layout.h;
    for (final fx in List<ClearFx>.of(effects)) {
      final t = fx.progress;
      if (t >= 1.0) continue;
      _paintOne(canvas, fx, t, layout, tile);
    }
  }

  void _paintOne(
    Canvas canvas,
    ClearFx fx,
    double t,
    HexLayout layout,
    double tile,
  ) {
    final pts = <Offset>[
      layout.centerOf(fx.head),
      for (final p in fx.rayCells) layout.centerOf(p),
    ];

    // Fading trail along the ray path — "the ray passed here" flash.
    if (pts.length >= 2) {
      final trail = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        trail.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = tile * 0.16
          ..color = fx.color.withValues(alpha: (1 - t) * 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Glow flying along the polyline and fading out.
    final ease = Curves.easeOut.transform(t);
    final pos = _pointAlong(pts, ease);
    canvas.drawCircle(
      pos,
      tile * 0.30 * (1 - t * 0.4),
      Paint()
        ..color = fx.color.withValues(alpha: 1 - t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.12),
    );
    canvas.drawCircle(
      pos,
      tile * 0.15,
      Paint()..color = Colors.white.withValues(alpha: 1 - t),
    );

    // Star pops for any collectibles the ray swept up.
    for (final s in fx.stars) {
      final c = layout.centerOf(s);
      final pop = math.sin(t * math.pi);
      _drawStar(
        canvas,
        c,
        tile * 0.20 * (1 + pop * 0.6),
        const Color(0xFFFFEE00).withValues(alpha: 1 - t * 0.3),
      );
    }
  }

  /// Point a fraction [f] (0..1) of the way along the polyline [pts].
  Offset _pointAlong(List<Offset> pts, double f) {
    if (pts.length == 1) return pts.first;
    final segs = <double>[];
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final l = (pts[i] - pts[i - 1]).distance;
      segs.add(l);
      total += l;
    }
    if (total == 0) return pts.first;
    var target = f * total;
    for (var i = 0; i < segs.length; i++) {
      if (target <= segs[i]) {
        final frac = segs[i] == 0 ? 0.0 : target / segs[i];
        return Offset.lerp(pts[i], pts[i + 1], frac)!;
      }
      target -= segs[i];
    }
    return pts.last;
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, Color color) {
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
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ClearFxPainter old) => true;
}

/// Full-screen confetti that rains down for the win celebration. Driven
/// by a 0..1 progress value.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.t});

  final double t;

  static final List<_Confetto> _pieces = _seed();

  static List<_Confetto> _seed() {
    final rng = math.Random(20260713);
    const palette = [
      Color(0xFFFF4D6D),
      Color(0xFF4DD0E1),
      Color(0xFFFFEE00),
      Color(0xFF9C6BFF),
      Color(0xFF4CAF50),
    ];
    return List.generate(90, (_) {
      return _Confetto(
        startX: rng.nextDouble(),
        speed: 0.6 + rng.nextDouble() * 0.9,
        drift: (rng.nextDouble() - 0.5) * 2,
        phase: rng.nextDouble() * math.pi * 2,
        spin: 2 + rng.nextDouble() * 6,
        size: 5 + rng.nextDouble() * 7,
        color: palette[rng.nextInt(palette.length)],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
    for (final p in _pieces) {
      final y = -20 + t * (size.height + 40) * p.speed;
      final x = p.startX * size.width +
          math.sin(t * 6 + p.phase) * 22 * p.drift;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.phase + t * p.spin * math.pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        Paint()..color = p.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter old) => old.t != t;
}

class _Confetto {
  _Confetto({
    required this.startX,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double startX;
  final double speed;
  final double drift;
  final double phase;
  final double spin;
  final double size;
  final Color color;
}
