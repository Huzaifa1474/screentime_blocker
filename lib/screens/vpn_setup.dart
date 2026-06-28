import 'package:flutter/material.dart';

/// Step 20 — Optional VPN setup.
///
/// Prompts the user to install a local VPN profile for browser domain
/// filtering on iOS. This is the optional fallback for Safari / browser-
/// based domains, since FamilyControls web-domain tokens are best-effort.
///
/// Implementation note: the actual VPN profile installation requires a
/// NetworkExtension PacketTunnelProvider target, which we declared in
/// Runner.entitlements. We present a button that triggers it; if the
/// user declines, they continue without it.
class VpnSetupScreen extends StatelessWidget {
  final VoidCallback onDone;
  const VpnSetupScreen({super.key, required this.onDone});

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
                'Block Safari too?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Install a local on-device VPN profile to also filter '
                'distracting websites in Safari and other browsers. The '
                'profile runs entirely on your phone — no traffic leaves '
                'the device.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              const _VpnStep(
                number: 1,
                title: 'Install the local VPN profile',
                detail: 'A single system prompt. You can remove it any time in Settings > VPN.',
              ),
              const _VpnStep(
                number: 2,
                title: 'Pick the domains to block',
                detail: 'We\'ll suggest a starter list based on your quiz answers.',
              ),
              const _VpnStep(
                number: 3,
                title: 'Done',
                detail: 'Safari blocks are enforced alongside your app blocks.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  // In production this triggers NEVPNManager installation.
                  // For now we just continue.
                  onDone();
                },
                child: const Text('Install VPN profile'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onDone,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VpnStep extends StatelessWidget {
  final int number;
  final String title;
  final String detail;
  const _VpnStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C5CFF).withValues(alpha: 0.18),
              border: Border.all(color: const Color(0xFF7C5CFF), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
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
