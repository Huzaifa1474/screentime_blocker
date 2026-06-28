import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/screentime_bridge.dart';

/// Deep Focus Mode.
///
/// Spec:
///   * No pause option, no override, no break.
///   * On iOS: call setAppUninstallRestriction(true) to block app removal.
///   * On Android: the AccessibilityService should detect if the user
///     navigates to the system Settings app and overlay a block screen
///     there too (handled in AppBlockerService).
///
/// This file provides:
///   * [DeepFocusController] — toggles the deep_focus_active pref + calls
///     the iOS-side restriction toggle.
///   * [DeepFocusInfoCard] — info card shown on the Rules Engine screen.
class DeepFocusController {
  DeepFocusController._();
  static final DeepFocusController instance = DeepFocusController._();

  static const String _kPrefKey = 'deep_focus_active';

  /// Activates Deep Focus Mode.
  ///
  /// On iOS, this calls setAppUninstallRestriction(true). On Android,
  /// it sets the `deep_focus_active` SharedPreferences flag which the
  /// AppBlockerService reads on every window event to decide whether
  /// to overlay the system Settings app.
  Future<bool> activate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKey, true);
    // iOS-only; Android returns false (no-op).
    await ScreentimeBridge.instance.setAppUninstallRestriction(true);
    return true;
  }

  Future<bool> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKey, false);
    await ScreentimeBridge.instance.setAppUninstallRestriction(false);
    return true;
  }

  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefKey) ?? false;
  }
}

/// Info card shown on the Rules Engine screen explaining Deep Focus Mode.
class DeepFocusInfoCard extends StatelessWidget {
  const DeepFocusInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C5CFF).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFB7A4FF), size: 18),
              SizedBox(width: 8),
              Text(
                'Deep Focus Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'When active: no pause, no override, no break. On iOS, app '
            'uninstall is blocked via ManagedSettings. On Android, the '
            'AccessibilityService overlays a block screen on the system '
            'Settings app so you can\'t disable the service or uninstall '
            'blockers mid-session.',
            style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
