import 'package:flutter/material.dart';

/// WaitingRoomDelay — mandatory progress-bar wait.
///
/// Spec: when a user tries to pause a session, show a progress bar with a
/// mandatory wait. Minimum 15 seconds, maximum 4 hours depending on
/// session type. The user CANNOT skip this.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(builder: (_) =>
///     WaitingRoomDelay(
///       wait: Duration(seconds: 15),
///       onComplete: () => _actuallyPause(),
///     ),
///   ));
class WaitingRoomDelay extends StatefulWidget {
  final Duration wait;
  final VoidCallback onComplete;

  const WaitingRoomDelay({
    super.key,
    required this.wait,
    required this.onComplete,
  });

  @override
  State<WaitingRoomDelay> createState() => _WaitingRoomDelayState();
}

class _WaitingRoomDelayState extends State<WaitingRoomDelay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.wait,
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _completed = true);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtRemaining() {
    final remaining = (1 - _ctrl.value) * widget.wait.inSeconds;
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pausing requires patience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You set this rule to slow yourself down. There\'s no skip button.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  return Column(
                    children: [
                      Text(
                        _fmtRemaining(),
                        style: const TextStyle(
                          color: Color(0xFFB7A4FF),
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _ctrl.value,
                          minHeight: 10,
                          backgroundColor: const Color(0xFF1C1C1E),
                          color: const Color(0xFF7C5CFF),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              if (_completed)
                FilledButton(
                  onPressed: widget.onComplete,
                  child: const Text('Pause now'),
                )
              else
                const Text(
                  'Hang tight. The button appears when the timer is done.',
                  style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
