import 'package:flutter_test/flutter_test.dart';

import 'package:screentime_blocker/main.dart';

void main() {
  testWidgets('App renders dashboard or onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreentimeBlockerApp(onboardingComplete: true));
    expect(find.byType(ScreentimeBlockerApp), findsOneWidget);
  });
}
