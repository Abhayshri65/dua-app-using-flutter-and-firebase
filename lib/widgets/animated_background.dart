import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_FloatingIcon> _icons = [
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.15, y: 0.12, dx: 10, dy: 6),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.45, y: 0.12, dx: -8, dy: 7),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.75, y: 0.16, dx: 9, dy: -6),
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.12, y: 0.28, dx: -7, dy: 8),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.40, y: 0.30, dx: 6, dy: -7),
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.70, y: 0.32, dx: -8, dy: 6),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.16, y: 0.58, dx: 6, dy: -5),
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.66, y: 0.54, dx: -6, dy: 7),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.78, y: 0.72, dx: 8, dy: -6),
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.36, y: 0.80, dx: -7, dy: 8),
    _FloatingIcon(icon: Icons.nights_stay_outlined, x: 0.20, y: 0.86, dx: 8, dy: -5),
    _FloatingIcon(icon: Icons.wb_sunny_outlined, x: 0.78, y: 0.88, dx: -9, dy: 6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
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
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          color: Colors.white,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                children: _icons.map((item) {
                  final dx = math.sin(t + item.phase) * item.dx;
                  final dy = math.cos(t + item.phase) * item.dy;
                  return Positioned(
                    left: item.x * width + dx,
                    top: item.y * height + dy,
                    child: Icon(
                      item.icon,
                      size: 36,
                      color: Colors.black87,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class _FloatingIcon {
  _FloatingIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
  }) : phase = math.Random().nextDouble() * 2 * math.pi;

  final IconData icon;
  final double x;
  final double y;
  final double dx;
  final double dy;
  final double phase;
}
