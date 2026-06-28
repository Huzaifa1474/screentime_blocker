import 'dart:async';
import 'package:flutter/material.dart';

import '../services/screentime_bridge.dart';

/// TakeABreak — clears shields for N minutes, then auto re-applies them.
///
/// Spec:
///   1. User picks a predefined break duration (5, 15, or 30 min).
///   2. Calls ScreentimeBridge.instance.setBlockingActive(false) to clear
///      shields.
///   3. Starts a local countdown timer.
///   4. When the timer expires, automatically calls setBlockingActive(true)
///      to re-apply shields. NO user action required to re-enable.
class TakeABreakScreen extends StatefulWidget {
  const TakeABreakScreen({super.key});

  @override
  State<TakeABreakScreen> createState() => _TakeABreakScreenState();
}

class _TakeABreakScreenState extends State<TakeABreakScreen> {
  static const _durations = <int>[5, 15, 30];
  int? _selected;
  Timer? _timer;
  int _remainingSeconds = 0;

  Future<void> _start() async {
    if (_selected == null) return;
    // Clear shields now.
    await ScreentimeBridge.instance.setBlockingActive(false);

    setState(() {
      _remainingSeconds = _selected! * 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        // Re-apply shields automatically — NO user action required.
        await ScreentimeBridge.instance.setBlockingActive(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Break over. Shields re-applied.')),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final running = _timer?.isActive ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Take a break')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pick a break length. We\'ll re-arm shields automatically.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (running) ...[
                Text(
                  _fmt(_remainingSeconds),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB7A4FF),
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shields are down. Re-arming the moment this hits zero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () async {
                    _timer?.cancel();
                    await ScreentimeBridge.instance.setBlockingActive(true);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('End break early'),
                ),
              ] else ...[
                Row(
                  children: _durations.map((d) {
                    final selected = _selected == d;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF7C5CFF).withValues(alpha: 0.18)
                                  : const Color(0xFF0F0F0F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF7C5CFF)
                                    : Colors.transparent,
                                width: 1.6,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$d',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'min',
                                  style: TextStyle(
                                    color: Color(0xFF8A8A8E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _selected == null ? null : _start,
                  child: const Text('Start break'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
