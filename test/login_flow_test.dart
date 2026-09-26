import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tmcebms/app/theme.dart';
import 'package:tmcebms/screens/auth/login_screen.dart';
import 'package:tmcebms/screens/dashboard/main_nav_screen.dart';
import 'package:tmcebms/state/app_state.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
      routes: {'/main': (_) => const MainNavScreen()},
    ),
  );
}

void main() {
  testWidgets('login with demo credentials navigates to dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen()));

    // Fill credentials using the demo account helper chip.
    await tester.tap(find.text('Student'));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'password123',
    );
    await tester.tap(find.text('Login'));
    await tester.pump(); // start the 500 ms simulated auth delay

    // Advance past the artificial delay and let navigation settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Dashboard should now be visible.
    expect(find.text('TMCEBMS'), findsNothing); // not used as an AppBar title anymore
    expect(find.textContaining('Welcome back to TMCEBMS'), findsOneWidget);
    expect(find.text('Total Borrowed'), findsOneWidget);
  });

  testWidgets('login with wrong password shows an error', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. student@tmc.edu'),
      'student@tmc.edu',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'wrong-password',
    );
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Invalid username/email or password.'), findsOneWidget);
  });
}
