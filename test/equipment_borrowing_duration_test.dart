import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmcebms/app/theme.dart';
import 'package:tmcebms/data/api_mappers.dart';
import 'package:tmcebms/models/equipment.dart';
import 'package:tmcebms/screens/borrowing/request_equipment_screen.dart';
import 'package:tmcebms/screens/equipment/equipment_details_screen.dart';
import 'package:tmcebms/state/app_state.dart';
import 'package:tmcebms/widgets/custom_button.dart';

Equipment equipment({int? min = 10, int? max = 15}) => mapEquipment({
  'id': 1,
  'name': 'Projector',
  'quantity': 5,
  'available_quantity': 5,
  'pickup_location': 'AV Office, Building A, Room 102',
  'min_borrowing_days': min,
  'max_borrowing_days': max,
  'borrowing_starts_on': '2020-01-01',
  'borrowing_ends_on': '2020-01-02',
});

class EquipmentAppState extends AppState {
  final Equipment item;
  EquipmentAppState(this.item);
  @override
  Equipment? equipmentById(String id) => item;
  @override
  Future<void> refreshEquipment({bool notify = true}) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppColors.isDark = false);

  test('10–15 days includes both limits and works across months and years', () {
    final item = equipment();
    final start = DateTime(2026, 10, 24);
    expect(item.pickupLocation, 'AV Office, Building A, Room 102');
    expect(item.minBorrowingDays, 10);
    expect(item.maxBorrowingDays, 15);
    expect(item.firstReturnDate(start), DateTime(2026, 11, 3));
    expect(item.lastReturnDate(start), DateTime(2026, 11, 8));
    for (final days in [9, 10, 15, 16]) {
      expect(
        item.allowsBorrowingPeriod(start, start.add(Duration(days: days))),
        days >= 10 && days <= 15,
      );
    }
    expect(
      item.allowsBorrowingPeriod(DateTime(2026, 12, 31), DateTime(2027, 1, 10)),
      isTrue,
    );
    expect(item.allowsBorrowingPeriod(start, start), isFalse);
  });

  test('legacy, exact and longer duration limits are supported', () {
    final start = DateTime(2026, 10, 24);
    final legacy = equipment(min: null, max: null);
    expect(legacy.allowsBorrowingPeriod(start, DateTime(2026, 10, 25)), isTrue);
    expect(legacy.allowsBorrowingPeriod(start, DateTime(2027, 2, 1)), isTrue);
    final exact = equipment(min: 10, max: 10);
    expect(exact.firstReturnDate(start), exact.lastReturnDate(start));
    expect(exact.allowsBorrowingPeriod(start, DateTime(2026, 11, 4)), isFalse);
    expect(
      equipment(min: 100, max: 120).lastReturnDate(start),
      DateTime(2027, 2, 21),
    );
    expect(mapEquipment({}).minBorrowingDays, isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'return picker enforces 10–15 days and resets after borrow date changes in ${brightness.name}',
      (tester) async {
        AppColors.isDark = brightness == Brightness.dark;
        final today = Equipment.schoolToday;
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>(
            create: (_) => EquipmentAppState(equipment()),
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const RequestEquipmentScreen(equipmentId: '1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('AV Office, Building A, Room 102'), findsOneWidget);
        expect(
          find.text('10–15 days after your borrowing date'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Select borrowing date'));
        await tester.tap(find.text('Select borrowing date'));
        await tester.pumpAndSettle();
        final picker = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        expect(picker.firstDate, today);
        expect(picker.lastDate, today.add(const Duration(days: 180)));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Select return date'));
        await tester.tap(find.text('Select return date'));
        await tester.pumpAndSettle();
        final returnPicker = tester.widget<CalendarDatePicker>(
          find.byType(CalendarDatePicker),
        );
        expect(returnPicker.firstDate, today.add(const Duration(days: 10)));
        expect(returnPicker.lastDate, today.add(const Duration(days: 15)));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Loan duration: 10 days'), findsOneWidget);
        final borrowingLabel = find.text(
          DateFormat('MMM d, yyyy').format(today),
        );
        await tester.ensureVisible(borrowingLabel);
        await tester.tap(borrowingLabel);
        await tester.pumpAndSettle();
        tester
            .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
            .onDateChanged(today.add(const Duration(days: 1)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Select return date'), findsOneWidget);
        expect(find.text('Loan duration: 10 days'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'equipment details show duration and remain requestable in ${brightness.name}',
      (tester) async {
        AppColors.isDark = brightness == Brightness.dark;
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>(
            create: (_) => EquipmentAppState(equipment()),
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const EquipmentDetailsScreen(equipmentId: '1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('AV Office, Building A, Room 102'), findsOneWidget);
        expect(
          find.text('10–15 days after your borrowing date'),
          findsOneWidget,
        );
        expect(
          tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
