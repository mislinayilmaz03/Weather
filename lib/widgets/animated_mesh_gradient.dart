import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Mesh Gradient background that slowly moves gradient orbs
/// to create a dynamic, weather-aware atmosphere.
class AnimatedMeshGradient extends StatefulWidget {
  final List<Color> colors;
  final Duration duration;
  final Widget? child;

  const AnimatedMeshGradient({
    super.key,
    required this.colors,
    this.duration = const Duration(seconds: 8),
    this.child,
  });

  @override
  State<AnimatedMeshGradient> createState() => _AnimatedMeshGradientState();
}

class _AnimatedMeshGradientState extends State<AnimatedMeshGradient>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_MeshOrb> _orbs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _generateOrbs();
  }

  void _generateOrbs() {
    final rng = math.Random(42);
    _orbs = List.generate(
      math.min(widget.colors.length, 5),
      (i) => _MeshOrb(
        color: widget.colors[i % widget.colors.length],
        startX: rng.nextDouble(),
        startY: rng.nextDouble(),
        radiusX: 0.3 + rng.nextDouble() * 0.4,
        radiusY: 0.2 + rng.nextDouble() * 0.3,
        speed: 0.5 + rng.nextDouble() * 0.8,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedMeshGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colors != widget.colors) {
      _generateOrbs();
    }
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
          painter: _MeshGradientPainter(
            orbs: _orbs,
            progress: _controller.value,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshOrb {
  final Color color;
  final double startX;
  final double startY;
  final double radiusX;
  final double radiusY;
  final double speed;
  final double phase;

  _MeshOrb({
    required this.color,
    required this.startX,
    required this.startY,
    required this.radiusX,
    required this.radiusY,
    required this.speed,
    required this.phase,
  });
}

class _MeshGradientPainter extends CustomPainter {
  final List<_MeshOrb> orbs;
  final double progress;

  _MeshGradientPainter({required this.orbs, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base color
    if (orbs.isNotEmpty) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = orbs.first.color.withOpacity(0.3),
      );
    }

    // Draw animated orbs with radial gradients
    for (int i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      final t = progress * math.pi * 2 * orb.speed + orb.phase;

      final cx = (orb.startX + math.sin(t) * 0.15) * size.width;
      final cy = (orb.startY + math.cos(t * 0.7) * 0.12) * size.height;
      final rx = orb.radiusX * size.width;
      final ry = orb.radiusY * size.height;

      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: rx * 2,
        height: ry * 2,
      );

      final gradient = RadialGradient(
        colors: [
          orb.color.withOpacity(0.6),
          orb.color.withOpacity(0.2),
          orb.color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.srcOver;

      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.orbs != orbs;
}
