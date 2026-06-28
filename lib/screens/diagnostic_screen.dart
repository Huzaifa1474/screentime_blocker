import 'package:flutter/material.dart';

import '../services/database_service.dart';

/// Step 2 — Diagnostic screen.
///
/// Asks the user for:
///   * their daily screentime estimate (slider, 0–12 hours)
///   * their primary focus goal (single-choice)
///
/// Both answers are persisted to SQLite for later use in the Day 6 report.
class DiagnosticScreen extends StatefulWidget {
  final VoidCallback onDone;
  const DiagnosticScreen({super.key, required this.onDone});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  double _hours = 4.0;
  String? _goal;

  static const _goals = <String>[
    'Reduce mindless scrolling',
    'Be more present with family',
    'Focus on deep work',
    'Sleep better at night',
    'Reclaim 1+ hours per day',
  ];

  Future<void> _save() async {
    await DatabaseService.instance
        .setDiagnostic('daily_estimate_hours', _hours.toStringAsFixed(1));
    if (_goal != null) {
      await DatabaseService.instance.setDiagnostic('focus_goal', _goal!);
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Let\'s get a quick read on you.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These answers shape your 14-day program. They stay on your device.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 40),

              // ---------- Daily estimate ----------
              const Text(
                'How many hours per day do you spend on your phone?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_hours.toStringAsFixed(1)} h',
                    style: const TextStyle(
                      color: Color(0xFF7C5CFF),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _hours,
                min: 0,
                max: 12,
                divisions: 24,
                activeColor: const Color(0xFF7C5CFF),
                onChanged: (v) => setState(() => _hours = v),
              ),
              const SizedBox(height: 32),

              // ---------- Focus goal ----------
              const Text(
                'What is your primary focus goal?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final g = _goals[i];
                    final selected = _goal == g;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _goal = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF7C5CFF).withValues(alpha: 0.18)
                              : const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF7C5CFF)
                                : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                g,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check,
                                  color: Color(0xFF7C5CFF), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _goal == null ? null : _save,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
