import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/screentime_bridge.dart';

/// Step 19 — Permission gateway.
///
/// Calls ScreentimeBridge.instance.requestSystemAuthorization().
/// The user CANNOT proceed until this returns true. The bridge, on iOS,
/// triggers FamilyControls authorization via FaceID/TouchID; on Android,
/// opens the system Accessibility settings and waits for the user to
/// enable our service.
class PermissionGatewayScreen extends StatefulWidget {
  final VoidCallback onAuthorized;
  const PermissionGatewayScreen({super.key, required this.onAuthorized});

  @override
  State<PermissionGatewayScreen> createState() =>
      _PermissionGatewayScreenState();
}

class _PermissionGatewayScreenState extends State<PermissionGatewayScreen> {
  bool _checking = false;
  String? _statusMessage;
  bool _authorized = false;

  Future<void> _request() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    final ok = await ScreentimeBridge.instance.requestSystemAuthorization();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _authorized = ok;
      _statusMessage = ok
          ? 'Authorized. You\'re all set.'
          : 'Not enabled yet. Tap the button again after you toggle it on.';
    });
    if (ok) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onAuthorized();
    }
  }

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
              const SizedBox(height: 32),
              const Text(
                'One permission.\nThen we never ask again.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Screentime Blocker uses your operating system\'s native '
                'screen-time controls to enforce blocks. We never see your '
                'app data, your browsing history, or your passwords.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              const _PermissionRow(
                icon: Icons.lock_outline,
                title: 'Family Controls (iOS)',
                detail: 'Required to apply ManagedSettings shields.',
              ),
              const _PermissionRow(
                icon: Icons.accessibility_new_outlined,
                title: 'Accessibility Service (Android)',
                detail: 'Required to detect when blocked apps open.',
              ),
              const Spacer(),
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _authorized
                        ? const Color(0xFF7C5CFF).withValues(alpha: 0.15)
                        : const Color(0xFF1A0F0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _authorized
                          ? const Color(0xFF7C5CFF)
                          : const Color(0xFFB00020),
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 240.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _checking ? null : _request,
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Grant permission'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => widget.onAuthorized(),
                child: const Text(
                  'Later',
                  style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFB7A4FF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF8A8A8E),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
