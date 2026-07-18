import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/position.dart';

/// HexLayout — odd-r offset, pointy-top hex geometry for a rows x cols
/// board fit into a canvas [size]. `h` is the hex height, `w = sqrt(3)/2
/// * h` its width. Rows with an odd index are shifted half a hex to the
/// right. Shared by the painter (draw) and the tap handler (hit-test) so
/// both agree on where each cell sits.
class HexLayout {
  final int rows;
  final int cols;
  final double h;
  final double w;
  final double originX;
  final double originY;

  HexLayout._(this.rows, this.cols, this.h, this.w, this.originX, this.originY);

  factory HexLayout(Size size, int rows, int cols) {
    final hFromHeight = size.height / (rows * 0.75 + 0.25);
    final hFromWidth = (size.width / (cols + 0.5)) / (math.sqrt(3) / 2);
    final h = math.min(hFromHeight, hFromWidth);
    final w = (math.sqrt(3) / 2) * h;
    final boardW = (cols + 0.5) * w;
    final boardH = (rows * 0.75 + 0.25) * h;
    return HexLayout._(
      rows,
      cols,
      h,
      w,
      (size.width - boardW) / 2,
      (size.height - boardH) / 2,
    );
  }

  /// Board width / height, so an enclosing AspectRatio matches the hexes.
  static double aspectRatio(int rows, int cols) =>
      ((cols + 0.5) * (math.sqrt(3) / 2)) / (rows * 0.75 + 0.25);

  Offset center(int row, int col) {
    final cx = originX + col * w + (row.isOdd ? w / 2 : 0.0) + w / 2;
    final cy = originY + row * (h * 0.75) + h / 2;
    return Offset(cx, cy);
  }

  Offset centerOf(Position p) => center(p.row, p.col);

  /// Vertices of the pointy-top hexagon centred at [c] (circumradius h/2).
  Path hexPath(Offset c) {
    final r = h / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 90);
      final p = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  /// Cell nearest to a local tap, or null if the tap is outside every
  /// hex (beyond the circumradius of the closest one). O(rows*cols),
  /// which is plenty for the small boards in play.
  Position? cellAt(Offset local) {
    final r = h / 2;
    Position? best;
    var bestD = double.infinity;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final d = (center(row, col) - local).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = Position(row, col);
        }
      }
    }
    if (best == null || bestD > r * r) return null;
    return best;
  }
}
