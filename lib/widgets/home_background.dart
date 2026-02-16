import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111D44),
                  Color(0xFF0C1536),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _IslamicPatternPainter(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: const SizedBox.expand(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.15,
                colors: [
                  Color(0x22000000),
                  Color(0x45000000),
                  Color(0x78000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66C9D0EF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const tile = 70.0;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;

    for (int y = -1; y <= rows; y++) {
      for (int x = -1; x <= cols; x++) {
        final ox = x * tile;
        final oy = y * tile;
        _drawMotif(canvas, paint, Offset(ox, oy), tile);
      }
    }
  }

  void _drawMotif(Canvas canvas, Paint paint, Offset origin, double tile) {
    final cx = origin.dx + tile / 2;
    final cy = origin.dy + tile / 2;
    final r = tile * 0.42;
    final inner = r * 0.55;

    final outer = Path();
    final innerPath = Path();

    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final px = cx + r * math.cos(a);
      final py = cy + r * math.sin(a);
      if (i == 0) {
        outer.moveTo(px, py);
      } else {
        outer.lineTo(px, py);
      }
    }
    outer.close();

    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      final px = cx + inner * math.cos(a);
      final py = cy + inner * math.sin(a);
      if (i == 0) {
        innerPath.moveTo(px, py);
      } else {
        innerPath.lineTo(px, py);
      }
    }
    innerPath.close();

    canvas.drawPath(outer, paint);
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
