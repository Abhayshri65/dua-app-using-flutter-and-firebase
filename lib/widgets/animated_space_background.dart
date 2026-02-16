import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedSpaceBackground extends StatefulWidget {
  const AnimatedSpaceBackground({super.key});

  @override
  State<AnimatedSpaceBackground> createState() => _AnimatedSpaceBackgroundState();
}

class _AnimatedSpaceBackgroundState extends State<AnimatedSpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_Star> _stars = const [
    _Star(0.06, 0.08, 1.2, 0.8),
    _Star(0.12, 0.18, 1.0, 0.7),
    _Star(0.2, 0.1, 1.4, 0.9),
    _Star(0.32, 0.12, 1.1, 0.75),
    _Star(0.44, 0.08, 1.2, 0.85),
    _Star(0.6, 0.12, 1.1, 0.8),
    _Star(0.72, 0.1, 1.3, 0.9),
    _Star(0.86, 0.14, 1.0, 0.7),
    _Star(0.92, 0.22, 1.4, 0.9),
    _Star(0.08, 0.3, 1.1, 0.75),
    _Star(0.18, 0.36, 1.0, 0.7),
    _Star(0.28, 0.34, 1.2, 0.8),
    _Star(0.42, 0.32, 1.0, 0.7),
    _Star(0.56, 0.28, 1.3, 0.85),
    _Star(0.7, 0.3, 1.1, 0.8),
    _Star(0.86, 0.34, 1.0, 0.7),
    _Star(0.1, 0.5, 1.0, 0.7),
    _Star(0.22, 0.56, 1.3, 0.85),
    _Star(0.38, 0.5, 1.1, 0.8),
    _Star(0.52, 0.48, 1.0, 0.7),
    _Star(0.68, 0.54, 1.2, 0.8),
    _Star(0.82, 0.52, 1.0, 0.7),
    _Star(0.1, 0.7, 1.2, 0.85),
    _Star(0.24, 0.76, 1.0, 0.7),
    _Star(0.38, 0.72, 1.1, 0.8),
    _Star(0.52, 0.7, 1.2, 0.8),
    _Star(0.66, 0.76, 1.0, 0.7),
    _Star(0.82, 0.72, 1.1, 0.8),
    _Star(0.92, 0.8, 1.2, 0.85),
    _Star(0.06, 0.86, 1.1, 0.8),
    _Star(0.2, 0.9, 1.0, 0.7),
    _Star(0.36, 0.88, 1.2, 0.85),
    _Star(0.56, 0.9, 1.1, 0.8),
    _Star(0.74, 0.88, 1.0, 0.7),
    _Star(0.9, 0.92, 1.2, 0.85),
  ];

  final List<_Sparkle> _sparkles = const [
    _Sparkle(0.38, 0.1, 10, 0.9),
    _Sparkle(0.68, 0.18, 12, 0.9),
    _Sparkle(0.58, 0.34, 10, 0.85),
    _Sparkle(0.84, 0.12, 12, 0.85),
  ];

  final List<_Moon> _moons = const [
    _Moon(0.88, 0.18, 96, 1.0, 0.45),
    _Moon(0.56, 0.36, 38, 0.75, 0.35),
    _Moon(0.22, 0.34, 24, 0.7, 0.3),
    _Moon(-0.04, 0.78, 80, 0.45, 0.25),
    _Moon(0.9, 0.82, 72, 0.5, 0.25),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;
            final starOffset = Offset(
              sin(t) * 1.5,
              cos(t * 0.8) * 1.2,
            );
            final moonOffset = Offset(
              sin(t * 0.7) * 4,
              cos(t * 0.6) * 3,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                const _SpaceGradient(),
                CustomPaint(
                  painter: _StarPainter(
                    stars: _stars,
                    sparkles: _sparkles,
                    drift: starOffset,
                  ),
                ),
                ..._moons.map((moon) {
                  final offset = moon.offset(size, moonOffset);
                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: Opacity(
                      opacity: moon.opacity,
                      child: _MoonWidget(size: moon.size),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _SpaceGradient extends StatelessWidget {
  const _SpaceGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050506),
            Color(0xFF0A0B10),
            Color(0xFF0E1016),
          ],
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.stars,
    required this.sparkles,
    required this.drift,
  });

  final List<_Star> stars;
  final List<_Sparkle> sparkles;
  final Offset drift;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white;
    for (final star in stars) {
      final dx = size.width * star.x + drift.dx * 0.4;
      final dy = size.height * star.y + drift.dy * 0.4;
      dotPaint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(Offset(dx, dy), star.radius, dotPaint);
    }

    final sparklePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final sparkle in sparkles) {
      final dx = size.width * sparkle.x + drift.dx * 0.6;
      final dy = size.height * sparkle.y + drift.dy * 0.6;
      sparklePaint.color = Colors.white.withOpacity(sparkle.opacity);
      final center = Offset(dx, dy);
      canvas.drawLine(
        Offset(center.dx, center.dy - sparkle.size / 2),
        Offset(center.dx, center.dy + sparkle.size / 2),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(center.dx - sparkle.size / 2, center.dy),
        Offset(center.dx + sparkle.size / 2, center.dy),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.drift != drift;
  }
}

class _MoonWidget extends StatelessWidget {
  const _MoonWidget({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.3),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _Star {
  const _Star(this.x, this.y, this.radius, this.opacity);

  final double x;
  final double y;
  final double radius;
  final double opacity;
}

class _Sparkle {
  const _Sparkle(this.x, this.y, this.size, this.opacity);

  final double x;
  final double y;
  final double size;
  final double opacity;
}

class _Moon {
  const _Moon(this.x, this.y, this.size, this.opacity, this.parallax);

  final double x;
  final double y;
  final double size;
  final double opacity;
  final double parallax;

  Offset offset(Size sizePx, Offset drift) {
    final dx = drift.dx * parallax;
    final dy = drift.dy * parallax;
    return Offset(sizePx.width * x + dx, sizePx.height * y + dy);
  }
}
