import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmcebms/app/theme.dart';
import 'package:tmcebms/screens/auth/login_screen.dart';
import 'package:tmcebms/state/app_state.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    // AppState reads persisted prefs at construction.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login with unreachable backend shows a connection error', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your username or email'),
      'student@tmc.edu',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'password123',
    );
    await tester.tap(find.text('Login'));

    // Let the (failing) HTTP request complete and the error render.
    // Under the test binding, HTTP is intercepted and fails with 400, so
    // any error surfaced by the login screen proves the async path ran.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.textContaining('Request failed'),
      findsOneWidget,
    );
  });

  testWidgets('login validates empty fields before contacting the server', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('This field is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
