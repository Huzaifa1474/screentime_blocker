import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Step 17 — Micro-commitment screen.
///
/// Requires the user to tap and hold a "fist bump" button for 2.5 seconds
/// to confirm intent. This is a deliberate behavioral micro-commitment:
/// a tap is reflexive, a hold is intentional.
class MicroCommitmentScreen extends StatefulWidget {
  final VoidCallback onDone;
  const MicroCommitmentScreen({super.key, required this.onDone});

  @override
  State<MicroCommitmentScreen> createState() => _MicroCommitmentScreenState();
}

class _MicroCommitmentScreenState extends State<MicroCommitmentScreen> {
  static const Duration _hold = Duration(seconds: 2, milliseconds: 500);
  double _progress = 0.0;
  bool _holding = false;
  bool _unlocked = false;

  void _start() {
    if (_unlocked) return;
    setState(() => _holding = true);
    _tick();
  }

  Future<void> _tick() async {
    while (_holding && _progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!_holding) return;
      setState(() {
        _progress += 50 / _hold.inMilliseconds;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _unlocked = true;
        }
      });
    }
    if (_unlocked) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) widget.onDone();
    }
  }

  void _cancel() {
    if (_unlocked) return;
    setState(() {
      _holding = false;
      _progress = 0;
    });
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
              const SizedBox(height: 64),
              const Text(
                'Make it real.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap and hold to commit to the next 14 days.\nReflex taps don\'t count.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14, height: 1.4),
              ),
              const Spacer(),
              GestureDetector(
                onTapDown: (_) => _start(),
                onTapUp: (_) => _cancel(),
                onTapCancel: _cancel,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F0F0F),
                    border: Border.all(
                      color: _unlocked
                          ? const Color(0xFF7C5CFF)
                          : const Color(0xFF2A2A2A),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.transparent,
                          color: const Color(0xFF7C5CFF),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.front_hand_outlined,
                            size: 64,
                            color: _unlocked
                                ? const Color(0xFFB7A4FF)
                                : Colors.white,
                          )
                              .animate(
                                  onPlay: (c) =>
                                      _unlocked ? c.repeat() : c.reset())
                              .scale(
                                duration: 800.ms,
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                              ),
                          const SizedBox(height: 8),
                          Text(
                            _unlocked ? 'Locked in' : 'Hold me',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _unlocked ? widget.onDone : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
