/// OnboardingStep — typed enumeration of every step in the onboarding flow.
///
/// The spec lists 24 steps. We model them as an enum so the router can
/// safely transition between them and persist progress.
enum OnboardingStep {
  splash,                // 1
  diagnostic,            // 2
  personalizationQuiz,   // 3-15 (collapsed; quiz has internal substeps)
  cognitiveShock,        // 16
  microCommitment,       // 17
  paywall,               // 18
  permissionGateway,     // 19
  vpnSetup,              // 20
  milestoneUnlock,       // 21
  dashboard,             // 22
  rulesEngine,           // 23
  waitingRoom,           // 24 (shown at runtime, not in onboarding)
}

extension OnboardingStepX on OnboardingStep {
  int get number {
    switch (this) {
      case OnboardingStep.splash: return 1;
      case OnboardingStep.diagnostic: return 2;
      case OnboardingStep.personalizationQuiz: return 3;
      case OnboardingStep.cognitiveShock: return 16;
      case OnboardingStep.microCommitment: return 17;
      case OnboardingStep.paywall: return 18;
      case OnboardingStep.permissionGateway: return 19;
      case OnboardingStep.vpnSetup: return 20;
      case OnboardingStep.milestoneUnlock: return 21;
      case OnboardingStep.dashboard: return 22;
      case OnboardingStep.rulesEngine: return 23;
      case OnboardingStep.waitingRoom: return 24;
    }
  }
}
