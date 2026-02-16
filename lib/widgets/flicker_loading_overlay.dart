import 'package:flutter/material.dart';

class FlickerLoadingOverlay extends StatelessWidget {
  const FlickerLoadingOverlay({
    super.key,
    required this.opacity,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
