import 'package:flutter/material.dart';

import '../widgets/breathing_animation.dart';
import '../features/color_game.dart';

/// Step 24 — Waiting room screen.
///
/// This is the in-app block screen shown when a user attempts to override
/// or pause a session. It shows:
///   * a breathing animation by default
///   * an optional color game (toggle) to break autopilot
///
/// (Note: on iOS, the actual native ShieldConfiguration extension renders
/// its own shield UI. This WaitingRoomScreen is the in-app equivalent
/// used for pause sequences, Take-a-Break endings, and pre-unblock
/// friction. On Android, the AppBlockerService draws its own system
/// overlay; this screen is shown when the user re-opens our app from
/// the overlay.)
class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _showColorGame = false;

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
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Spacer(),
              if (!_showColorGame) ...[
                const BreathingAnimation(size: 240),
                const SizedBox(height: 32),
                const Text(
                  'Breathe in for 4 seconds.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You set this rule for a reason. There\'s nothing on that\n'
                  'app that can\'t wait 4 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13, height: 1.5),
                ),
              ] else ...[
                const ColorGame(),
              ],
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => setState(() => _showColorGame = !_showColorGame),
                child: Text(_showColorGame
                    ? 'Back to breathing'
                    : 'Try the color game'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I\'ll keep going'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
