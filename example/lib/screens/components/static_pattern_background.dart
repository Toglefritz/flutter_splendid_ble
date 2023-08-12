import 'dart:math';
import 'package:flutter/material.dart';

/// They say we eat first with our eyes. That that in mind, this is a widget that creates an aesthetic background
/// effect resembling a subtle static pattern or light dust.
///
/// This effect slowly drifts across the screen from the upper-right corner to the lower-left corner. It can be used
/// as a background within the body of a [Scaffold].
///
/// The [child] widget is displayed on top of this background.
class StaticPatternBackground extends StatefulWidget {
  const StaticPatternBackground({super.key, required this.child});

  /// The child widget that is displayed on top of the background.
  final Widget child;

  @override
  StaticPatternBackgroundState createState() => StaticPatternBackgroundState();
}

/// The stateful logic for the [StaticPatternBackground] widget.
class StaticPatternBackgroundState extends State<StaticPatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StaticPatternPainter(_controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A custom painter that draws the subtle static pattern or light dust effect.
///
/// The effect is drawn as small circles that drift across the screen.
class _StaticPatternPainter extends CustomPainter {
  final double progress;

  _StaticPatternPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.8)
      ..strokeWidth = 2.0;

    const numberOfParticles = 100;
    final Random random = Random();
    for (int i = 0; i < numberOfParticles; i++) {
      final x = (random.nextDouble() * size.width + progress * size.width) %
          size.width;
      final y = (random.nextDouble() * size.height + progress * size.height) %
          size.height;
      canvas.drawCircle(Offset(x, y), 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
