import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmcebms/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding pages swipe and finish without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        routes: {'/login': (_) => const SizedBox()},
        home: const OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // First page content is visible.
    expect(find.text('Easy Equipment Access'), findsOneWidget);

    // Swipe to the last page.
    await tester.fling(find.text('Easy Equipment Access'), const Offset(-400, 0), 800);
    await tester.pumpAndSettle();
    expect(find.text('Track Everything'), findsOneWidget);

    // Finish onboarding.
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Easy Equipment Access'), findsNothing);
  });
}
