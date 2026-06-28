import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';

/// Step 1 — Splash screen.
///
/// Black background (#000000). Initializes the local SQLite database.
/// Shows a brief logo animation, then calls [onDone].
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing…';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _status = 'Initializing local database…');
    // Open / create the SQLite database. This is where the 14-day program,
    // focus scores, and milestones will live.
    await DatabaseService.instance.db;

    setState(() => _status = 'Ready');
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark — a faceted "gem" shape rendered with a
            // diamond outline and an animated scale-in.
            const Icon(
              Icons.diamond_outlined,
              size: 96,
              color: Color(0xFF7C5CFF),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 1400.ms,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.05, 1.05),
                )
                .shimmer(
                  duration: 1800.ms,
                  color: const Color(0xFFB7A4FF),
                ),
            const SizedBox(height: 24),
            const Text(
              'Screentime Blocker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
