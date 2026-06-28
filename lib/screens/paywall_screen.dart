import 'package:flutter/material.dart';

/// Step 18 — Paywall screen.
///
/// 7-day free trial on a yearly plan. Includes before/after comparison cards.
class PaywallScreen extends StatelessWidget {
  final VoidCallback onDone;
  const PaywallScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                '7 days free.\nThen 1 year of focus.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '\$39.99/year after the trial. Cancel anytime.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // ---------- Before / After comparison ----------
              const Row(
                children: [
                  Expanded(
                    child: _CompareCard(
                      title: 'Before',
                      tone: _CompareTone.negative,
                      bullets: [
                        '3h+ of mindless scrolling',
                        'Constant notifications',
                        'Willpower-based blocking',
                        'No data, no milestones',
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _CompareCard(
                      title: 'After',
                      tone: _CompareTone.positive,
                      bullets: [
                        'Native OS-level blocks',
                        '14-day guided program',
                        'Focus Score & reports',
                        'Shareable 3D gems',
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ---------- Plan card ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7C5CFF),
                    width: 1.6,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annual',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '7-day free trial',
                          style:
                              TextStyle(color: Color(0xFFB7A4FF), fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '\$39.99/yr',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onDone,
                child: const Text('Start 7-day free trial'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onDone,
                child: const Text('Maybe later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CompareTone { positive, negative }

class _CompareCard extends StatelessWidget {
  final String title;
  final _CompareTone tone;
  final List<String> bullets;
  const _CompareCard({
    required this.title,
    required this.tone,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone == _CompareTone.positive
        ? const Color(0xFF7C5CFF)
        : const Color(0xFF5A5A5A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tone == _CompareTone.positive
                        ? Icons.check
                        : Icons.close,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
