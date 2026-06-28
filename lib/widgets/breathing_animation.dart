import 'package:flutter/material.dart';

/// BreathingAnimation — a slowly expanding/contracting circle used in
/// the Waiting Room screen (Step 24) and on the iOS ShieldConfiguration
/// extension. Pacing is 4s inhale / 4s exhale.
class BreathingAnimation extends StatefulWidget {
  final double size;
  final Color color;
  const BreathingAnimation({
    super.key,
    this.size = 220,
    this.color = const Color(0xFF7C5CFF),
  });

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOutSine.transform(_ctrl.value);
        final scale = 0.7 + (t * 0.5);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.18),
                ),
              ),
              Container(
                width: widget.size * scale * 0.65,
                height: widget.size * scale * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.32),
                ),
              ),
              Container(
                width: widget.size * scale * 0.35,
                height: widget.size * scale * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
