import 'package:flutter/material.dart';

/// ColorGame — Stroop-style interference task.
///
/// Displays a color-name WORD (e.g. "RED") rendered in a FONT color that
/// may differ from the word's meaning (e.g. the word "RED" written in
/// blue font). The user must tap the color of the FONT, not the meaning
/// of the word. Used during unblock sequences to break autopilot.
///
/// The game requires N consecutive correct answers before allowing the
/// user to proceed.
class ColorGame extends StatefulWidget {
  final int requiredCorrect;
  const ColorGame({super.key, this.requiredCorrect = 3});

  @override
  State<ColorGame> createState() => _ColorGameState();
}

class _ColorGameState extends State<ColorGame> {
  static const _colors = <_NamedColor>[
    _NamedColor('RED', Color(0xFFFF3B30)),
    _NamedColor('GREEN', Color(0xFF34C759)),
    _NamedColor('BLUE', Color(0xFF0A84FF)),
    _NamedColor('YELLOW', Color(0xFFFFD60A)),
    _NamedColor('PURPLE', Color(0xFF7C5CFF)),
  ];

  late _NamedColor _word;
  late _NamedColor _font;
  int _correct = 0;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final rnd = DateTime.now().microsecondsSinceEpoch;
    _word = _colors[rnd % _colors.length];
    _font = _colors[(rnd ~/ 31) % _colors.length];
    while (_font.name == _word.name) {
      _font = _colors[(rnd ~/ 97 + _correct) % _colors.length];
    }
    _feedback = null;
    setState(() {});
  }

  void _pick(_NamedColor c) {
    if (c.name == _font.name) {
      _correct++;
      _feedback = 'Correct.';
      if (_correct >= widget.requiredCorrect) {
        // Win condition. Caller (WaitingRoomScreen / WaitingRoomDelay)
        // can pop or proceed.
        _feedback = 'Done. You may proceed.';
        setState(() {});
        return;
      }
    } else {
      _correct = 0;
      _feedback = 'That was the meaning, not the font color. Try again.';
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), _next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Tap the color of the FONT',
          style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress: $_correct / ${widget.requiredCorrect}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Text(
          _word.name,
          style: TextStyle(
            color: _font.color,
            fontSize: 64,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 48),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _colors.map((c) {
            return GestureDetector(
              onTap: () => _pick(c),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        if (_feedback != null)
          Text(
            _feedback!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _correct >= widget.requiredCorrect
                  ? const Color(0xFFB7A4FF)
                  : Colors.white,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class _NamedColor {
  final String name;
  final Color color;
  const _NamedColor(this.name, this.color);
}
