import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Step 21 — First milestone.
///
/// Shows a 3D animated gem unlock on a black background. We use a
/// custom-painted diamond with a rotating specular highlight to imply
/// 3D depth without pulling in a 3D engine dependency. The gem is
/// "unlocked" by the user completing onboarding.
class MilestoneUnlockScreen extends StatefulWidget {
  final VoidCallback onDone;
  const MilestoneUnlockScreen({super.key, required this.onDone});

  @override
  State<MilestoneUnlockScreen> createState() => _MilestoneUnlockScreenState();
}

class _MilestoneUnlockScreenState extends State<MilestoneUnlockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Milestone unlocked',
                style: TextStyle(
                  color: Color(0xFFB7A4FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms),
              const SizedBox(height: 12),
              const Text(
                'Day 0 · Onboarding',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: 240,
                height: 240,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _GemPainter(_controller.value),
                    );
                  },
                ),
              )
                  .animate()
                  .scale(
                    duration: 900.ms,
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 400.ms),
              const Spacer(),
              const Text(
                '14 days from now, you\'ll have unlocked a full set.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.onDone,
                child: const Text('Enter the app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// _GemPainter — paints a faceted diamond with a moving specular highlight.
///
/// This is a "pseudo-3D" approach: we draw the diamond as a series of
/// triangular facets, each filled with a slightly different shade, and
/// move a bright streak across it to imply motion / depth. For true 3D
/// you'd swap in flutter_gl or Rive; this keeps the binary small.
class _GemPainter extends CustomPainter {
  final double t; // 0..1
  _GemPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.5;
    final h = size.height * 0.55;

    final top = Offset(cx, cy - h);
    final bottom = Offset(cx, cy + h);
    final left = Offset(cx - w, cy);
    final right = Offset(cx + w, cy);

    // Crown (top half) — split into 4 triangular facets.
    final crownFacets = [
      [top, left, Offset(cx, cy)],
      [top, Offset(cx, cy), right],
      [top, right, Offset(cx + w * 0.5, cy - h * 0.2)],
      [top, Offset(cx - w * 0.5, cy - h * 0.2), left],
    ];

    // Pavilion (bottom half) — split into 4 triangular facets.
    final pavilionFacets = [
      [bottom, left, Offset(cx, cy)],
      [bottom, Offset(cx, cy), right],
      [bottom, right, Offset(cx + w * 0.5, cy + h * 0.2)],
      [bottom, Offset(cx - w * 0.5, cy + h * 0.2), left],
    ];

    // Bright streak position — moves left-to-right across the gem.
    final streakX = cx + (math.sin(t * 2 * math.pi) * w * 0.8);

    for (final f in [...crownFacets, ...pavilionFacets]) {
      final path = Path()..moveTo(f[0].dx, f[0].dy);
      path.lineTo(f[1].dx, f[1].dy);
      path.lineTo(f[2].dx, f[2].dy);
      path.close();

      // Distance of facet centroid from the streak — closer = brighter.
      final fx = (f[0].dx + f[1].dx + f[2].dx) / 3;
      final dist = (fx - streakX).abs();
      final brightness = (1.0 - dist / w).clamp(0.0, 1.0);

      const base = Color(0xFF7C5CFF);
      final light = Color.lerp(base, Colors.white, brightness * 0.6)!;
      final dark = Color.lerp(base, Colors.black, 0.4)!;
      final color = Color.lerp(dark, light, brightness)!;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      final stroke = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, stroke);
    }

    // Outer outline
    final outline = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter old) => old.t != t;
}
