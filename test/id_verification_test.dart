import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmcebms/app/theme.dart';
import 'package:tmcebms/data/api_mappers.dart';
import 'package:tmcebms/models/user.dart';
import 'package:tmcebms/screens/profile/profile_screen.dart';
import 'package:tmcebms/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    testWidgets('rejected ID can be resubmitted in ${brightness.name} mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AppColors.isDark = brightness == Brightness.dark;
      addTearDown(() => AppColors.isDark = false);
      final state = AppState();
      await tester.pumpAndSettle();
      addTearDown(state.dispose);

      final submission = <String, dynamic>{
        'id': 1,
        'first_name': 'Student',
        'account_status': 'Pending',
        'is_id_verified': false,
        'id_submitted_at': '2026-10-22T00:00:00Z',
      };
      state.currentUser = mapUser(submission);
      expect(state.idVerificationStatus, IdVerificationStatus.pending);
      state.currentUser = mapUser({
        ...submission,
        'id_rejection_reason': 'The back of your ID is blurry.',
      });
      expect(state.idVerificationStatus, IdVerificationStatus.rejected);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('The back of your ID is blurry.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('The back of your ID is blurry.'),
        findsOneWidget,
      );
      expect(find.text('Tap to add a photo'), findsNWidgets(2));
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap to add a photo').first);
      await tester.pumpAndSettle();
      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Tap to add a photo'), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      state.currentUser = mapUser(submission);
      expect(state.idVerificationStatus, IdVerificationStatus.pending);
      state.currentUser = mapUser({...submission, 'is_id_verified': true});
      expect(state.idVerificationStatus, IdVerificationStatus.approved);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
