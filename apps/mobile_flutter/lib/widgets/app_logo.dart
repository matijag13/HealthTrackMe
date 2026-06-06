import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';

/// HealthTrackMe brand logo: a gradient squircle with a white heart that has
/// an ECG/heartbeat pulse line knocked out of it.
///
/// Drawn natively with a [CustomPainter] so it stays crisp at any size and
/// needs no image asset. Matches assets/images/logo_*.png.
///
/// ```dart
/// const AppLogo(size: 96)                       // full gradient icon
/// const AppLogo(size: 48, background: false)    // white glyph only (for dark bars)
/// ```
class AppLogo extends StatelessWidget {
  final double size;

  /// When false, the gradient squircle is omitted and only the heart glyph is
  /// drawn (in [glyphColor]) — useful on top of an existing colored surface.
  final bool background;

  /// Color of the heart when [background] is false. Ignored otherwise.
  final Color glyphColor;

  /// Gradient used for the squircle background.
  final List<Color> gradient;

  const AppLogo({
    super.key,
    this.size = 64,
    this.background = true,
    this.glyphColor = Colors.white,
    this.gradient = const [Color(0xFF4A7CE8), Color(0xFF7C4AF0)],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          background: background,
          glyphColor: glyphColor,
          gradient: gradient,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool background;
  final Color glyphColor;
  final List<Color> gradient;

  _LogoPainter({
    required this.background,
    required this.glyphColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & Size(s, s),
      Radius.circular(s * 0.235),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    if (background) {
      final bg = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ).createShader(Offset.zero & Size(s, s));
      canvas.drawRRect(rrect, bg);

      // soft top-left sheen
      canvas.drawOval(
        Rect.fromLTWH(-s * 0.25, -s * 0.45, s * 1.10, s),
        Paint()..color = Colors.white.withValues(alpha: 0.11),
      );
    }

    // Heart + ECG knockout, painted on its own layer so blend-clear works.
    canvas.saveLayer(Offset.zero & Size(s, s), Paint());
    canvas.drawPath(
      _heartPath(s, cx: s * 0.5, cy: s * 0.49, scale: s * 0.0242),
      Paint()
        ..color = background ? Colors.white : glyphColor
        ..isAntiAlias = true,
    );
    canvas.drawPoints(
      PointMode.polygon,
      _ecgPoints(s),
      Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = s * 0.052
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();

    canvas.restore();
  }

  Path _heartPath(double s,
      {required double cx, required double cy, required double scale}) {
    final path = Path();
    const steps = 200;
    for (var i = 0; i <= steps; i++) {
      final t = 2 * math.pi * i / steps;
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y = 13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t);
      final px = cx + x * scale;
      final py = cy - y * scale;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  List<Offset> _ecgPoints(double s) {
    const norm = [
      [0.04, 0.50],
      [0.32, 0.50],
      [0.385, 0.40],
      [0.45, 0.66],
      [0.52, 0.255],
      [0.60, 0.60],
      [0.66, 0.50],
      [0.96, 0.50],
    ];
    return [for (final p in norm) Offset(p[0] * s, p[1] * s)];
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.background != background ||
      old.glyphColor != glyphColor ||
      old.gradient != gradient;
}
