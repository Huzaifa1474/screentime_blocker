import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/database_service.dart';
import 'services/rules_engine.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_router.dart';
import 'screens/dashboard.dart';

/// Entry point. Initializes local SQLite, registers services, and
/// routes the user to either onboarding (first launch) or dashboard.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Eagerly open the SQLite database so Step 1 (Splash) can show a
  // meaningful "initializing" state.
  await DatabaseService.instance.db;

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(ScreentimeBlockerApp(
    onboardingComplete: onboardingComplete,
  ));
}

class ScreentimeBlockerApp extends StatelessWidget {
  final bool onboardingComplete;
  const ScreentimeBlockerApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RulesEngineService>.value(
          value: RulesEngineService.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Screentime Blocker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: onboardingComplete
            ? const DashboardScreen()
            : const OnboardingRouter(),
      ),
    );
  }
}
