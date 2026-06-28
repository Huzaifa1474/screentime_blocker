import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FocusScoreDial — circular gauge (0..100) shown on the dashboard.
///
/// Renders an arc from -220deg to +40deg (a 260deg sweep). Filled
/// portion represents the score; the empty portion is muted.
class FocusScoreDial extends StatefulWidget {
  final int score; // 0..100
  final double size;
  const FocusScoreDial({super.key, required this.score, this.size = 220});

  @override
  State<FocusScoreDial> createState() => _FocusScoreDialState();
}

class _FocusScoreDialState extends State<FocusScoreDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant FocusScoreDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return CustomPaint(
            painter: _DialPainter(_anim.value * widget.score.clamp(0, 100)),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double score;
  _DialPainter(this.score);

  static const double _startAngle = -220 * math.pi / 180;
  static const double _sweep = 260 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    final center = Offset(cx, cy);

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      _startAngle,
      _sweep,
      false,
      Paint()
        ..color = const Color(0xFF1C1C1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // Filled ring
    final filledSweep = _sweep * (score / 100);
    const gradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweep,
      colors: [Color(0xFF7C5CFF), Color(0xFFB7A4FF)],
      stops: [0.0, 1.0],
      transform: GradientRotation(_startAngle),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      _startAngle,
      filledSweep,
      false,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: r),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        text: score.round().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 - 4));

    final tp2 = TextPainter(
      text: const TextSpan(
        text: 'Focus Score',
        style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(
      canvas,
      Offset(cx - tp2.width / 2, cy + tp.height / 2 - 4),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.score != score;
}
