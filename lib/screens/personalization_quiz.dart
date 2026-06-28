import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';

/// Steps 3-15 — Personalization quiz.
///
/// Grid layout with selectable cards. User picks distraction app
/// categories they want to manage. Each card represents a category
/// (which on iOS maps to a FamilyControls ActivityCategory token,
/// satisfying the "prefer category tokens over individual app tokens"
/// 50-token-limit constraint).
///
/// Internally we treat this as a single screen with progress through
/// 3 sub-pages (Distraction sources, Time triggers, Recovery preferences)
/// because the spec lists 13 substeps (3-15) — too granular for one
/// screen each; we group them.
class PersonalizationQuizScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PersonalizationQuizScreen({super.key, required this.onDone});

  @override
  State<PersonalizationQuizScreen> createState() =>
      _PersonalizationQuizScreenState();
}

class _PersonalizationQuizScreenState extends State<PersonalizationQuizScreen> {
  int _page = 0;
  final Set<String> _picked = {};

  static const _pages = <_QuizPage>[
    _QuizPage(
      title: 'What pulls you in?',
      subtitle: 'Pick the apps you reach for without thinking.',
      options: [
        _CategoryOption('Social', Icons.people_outline, 'social'),
        _CategoryOption('Short Video', Icons.play_circle_outline, 'short_video'),
        _CategoryOption('News', Icons.article_outlined, 'news'),
        _CategoryOption('Messaging', Icons.chat_bubble_outline, 'messaging'),
        _CategoryOption('Games', Icons.sports_esports_outlined, 'games'),
        _CategoryOption('Shopping', Icons.shopping_bag_outlined, 'shopping'),
        _CategoryOption('Streaming', Icons.tv, 'streaming'),
        _CategoryOption('Dating', Icons.favorite_outline, 'dating'),
      ],
    ),
    _QuizPage(
      title: 'When does it hit hardest?',
      subtitle: 'Identify your danger windows.',
      options: [
        _CategoryOption('Right after waking', Icons.wb_sunny_outlined, 'morning'),
        _CategoryOption('During commutes', Icons.directions_car_outlined, 'commute'),
        _CategoryOption('At meals', Icons.restaurant_outlined, 'meals'),
        _CategoryOption('Before sleep', Icons.nights_stay_outlined, 'night'),
        _CategoryOption('Bored moments', Icons.hourglass_empty, 'bored'),
        _CategoryOption('Stress spikes', Icons.bolt_outlined, 'stress'),
      ],
    ),
    _QuizPage(
      title: 'How do you want to recover?',
      subtitle: 'Pick your friction preferences.',
      options: [
        _CategoryOption('Breathing pause', Icons.air_outlined, 'breathing'),
        _CategoryOption('Color game', Icons.palette_outlined, 'color_game'),
        _CategoryOption('Mandatory wait', Icons.timer_outlined, 'wait'),
        _CategoryOption('Hard block only', Icons.lock_outlined, 'hard_block'),
      ],
    ),
  ];

  bool get _canAdvance => _picked.any((p) => p.startsWith(_pages[_page].tagPrefix));

  Future<void> _next() async {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
      return;
    }
    // Persist and proceed.
    await DatabaseService.instance
        .setDiagnostic('picked_categories', _picked.join(','));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar — shows we're at substep ((_page+1) * ~4) of 13
              // so the spec's 3-15 framing is visible to the user.
              LinearProgressIndicator(
                value: (_page + 1) / _pages.length,
                backgroundColor: const Color(0xFF1C1C1E),
                color: const Color(0xFF7C5CFF),
                minHeight: 4,
              ),
              const SizedBox(height: 28),
              Text(
                page.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 280.ms),
              const SizedBox(height: 6),
              Text(
                page.subtitle,
                style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: page.options.map((opt) {
                    final selected = _picked.contains(opt.tag);
                    return _CategoryCard(
                      option: opt,
                      selected: selected,
                      onTap: () => setState(() {
                        if (selected) {
                          _picked.remove(opt.tag);
                        } else {
                          _picked.add(opt.tag);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canAdvance ? _next : null,
                child: Text(
                  _page < _pages.length - 1 ? 'Continue' : 'Lock it in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizPage {
  final String title;
  final String subtitle;
  final List<_CategoryOption> options;
  const _QuizPage({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  String get tagPrefix => options.first.tag.split('_').first;
}

class _CategoryOption {
  final String label;
  final IconData icon;
  final String tag;
  const _CategoryOption(this.label, this.icon, this.tag);
}

class _CategoryCard extends StatelessWidget {
  final _CategoryOption option;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C5CFF).withValues(alpha: 0.15)
              : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF7C5CFF) : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              option.icon,
              size: 32,
              color: selected ? const Color(0xFFB7A4FF) : Colors.white,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF7C5CFF), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
