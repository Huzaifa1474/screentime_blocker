import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_step.dart';
import 'splash_screen.dart';
import 'diagnostic_screen.dart';
import 'personalization_quiz.dart';
import 'cognitive_shock.dart';
import 'micro_commitment.dart';
import 'paywall_screen.dart';
import 'permission_gateway.dart';
import 'vpn_setup.dart';
import 'milestone_unlock.dart';
import 'dashboard.dart';

/// OnboardingRouter
///
/// Persists the current step in SharedPreferences so a user who kills the
/// app mid-onboarding resumes at the right place. The user cannot reach
/// the Dashboard until Step 19 (Permission Gateway) returns true.
class OnboardingRouter extends StatefulWidget {
  const OnboardingRouter({super.key});

  @override
  State<OnboardingRouter> createState() => _OnboardingRouterState();
}

class _OnboardingRouterState extends State<OnboardingRouter> {
  OnboardingStep _step = OnboardingStep.splash;

  @override
  void initState() {
    super.initState();
    _loadSavedStep();
  }

  Future<void> _loadSavedStep() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('onboarding_step') ?? 0;
    if (mounted) {
      setState(() {
        _step = OnboardingStep.values[idx.clamp(
          0,
          OnboardingStep.values.length - 1,
        )];
      });
    }
  }

  Future<void> _goTo(OnboardingStep next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboarding_step', next.index);
    if (mounted) {
      setState(() => _step = next);
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case OnboardingStep.splash:
        return SplashScreen(onDone: () => _goTo(OnboardingStep.diagnostic));
      case OnboardingStep.diagnostic:
        return DiagnosticScreen(
            onDone: () => _goTo(OnboardingStep.personalizationQuiz));
      case OnboardingStep.personalizationQuiz:
        return PersonalizationQuizScreen(
            onDone: () => _goTo(OnboardingStep.cognitiveShock));
      case OnboardingStep.cognitiveShock:
        return CognitiveShockScreen(
            onDone: () => _goTo(OnboardingStep.microCommitment));
      case OnboardingStep.microCommitment:
        return MicroCommitmentScreen(
            onDone: () => _goTo(OnboardingStep.paywall));
      case OnboardingStep.paywall:
        return PaywallScreen(
            onDone: () => _goTo(OnboardingStep.permissionGateway));
      case OnboardingStep.permissionGateway:
        return PermissionGatewayScreen(
          // CRITICAL: do not let the user proceed until authorization
          // returns true.
          onAuthorized: () => _goTo(OnboardingStep.vpnSetup),
        );
      case OnboardingStep.vpnSetup:
        return VpnSetupScreen(
            onDone: () => _goTo(OnboardingStep.milestoneUnlock));
      case OnboardingStep.milestoneUnlock:
        return MilestoneUnlockScreen(onDone: _complete);
      case OnboardingStep.dashboard:
      case OnboardingStep.rulesEngine:
      case OnboardingStep.waitingRoom:
        // These are reachable from the Dashboard after onboarding completes.
        return const DashboardScreen();
    }
  }
}
