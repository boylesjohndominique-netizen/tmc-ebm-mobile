import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmcebms/data/api_mappers.dart';
import 'package:tmcebms/data/receipt_exporter.dart';
import 'package:tmcebms/models/borrowing_receipt.dart';
import 'package:tmcebms/models/borrowing_transaction.dart';
import 'package:tmcebms/screens/borrowing/borrowing_receipt_screen.dart';
import 'package:tmcebms/state/app_state.dart';

Map<String, dynamic> receiptJson() => {
  'transaction_code': '123456789012',
  'qr_payload': 'TMCEBMS:${'a' * 64}',
  'status': 'Approved',
  'pickup_status': 'Awaiting',
  'borrower': {'name': 'María Niño', 'id_number': '24-123456'},
  'approved_by': 'Equipment Admin',
  'borrower_remarks': 'Class presentation',
  'approval_remarks': 'Collect from the AV office',
  'pickup_starts_at': '2026-10-22T01:00:00Z',
  'pickup_ends_at': '2026-10-22T03:00:00Z',
  'borrowing_date': '2026-10-22',
  'expected_return_date': '2026-10-24',
  'items': [
    {
      'equipment_id': 1,
      'name': 'Projector',
      'quantity': 2,
      'category': 'AV',
      'condition': 'Good',
      'description': 'HDMI projector with remote',
    },
  ],
};

class ReceiptAppState extends AppState {
  final bool returnMode;
  ReceiptAppState({this.returnMode = false});
  @override
  List<BorrowingTransaction> get transactions => [
    mapBorrowing({
      'id': 13,
      'status': 'Approved',
      'pickup_status': 'Awaiting',
      'receipt': receiptJson(),
      if (returnMode)
        'returns': [
          {'id': 4, 'status': 'Approved', 'receipt': returnReceiptJson()},
        ],
    }),
  ];
}

Map<String, dynamic> returnReceiptJson() => {
  ...receiptJson(),
  'kind': 'return',
  'transaction_code': '987654321012',
  'qr_payload': 'TMCEBMS:RETURN:${'b' * 64}',
  'handover_status': 'Awaiting',
  'handover_starts_at': '2026-10-22T01:00:00Z',
  'handover_ends_at': '2026-10-22T03:00:00Z',
  'borrowing_transaction_code': '123456789012',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'PDF export produces a complete document for a multi-item receipt',
    () async {
      final json = receiptJson();
      json['items'] = List.generate(
        18,
        (index) => {
          'equipment_id': index + 1,
          'name': 'Equipment ${index + 1}',
          'quantity': 1,
          'description': 'Equipment description with accessories',
        },
      );
      final receipt = BorrowingReceipt.fromJson(json);
      expect(
        (await rootBundle.load(
          'assets/fonts/NotoSans-Regular.ttf',
        )).lengthInBytes,
        greaterThan(100000),
      );
      expect(
        (await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')).lengthInBytes,
        greaterThan(100000),
      );
      final bytes = await ReceiptExporter.pdf(receipt);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(latin1.decode(bytes), contains('%%EOF'));
      expect(bytes.length, greaterThan(2000));
    },
  );

  for (final isReturn in [false, true]) {
    testWidgets(
      'image and PDF buttons export correctly named ${isReturn ? 'return' : 'borrowing'} receipt files',
      (tester) async {
        final sharedFiles = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            sharedFiles.addAll(
              List<String>.from((call.arguments as Map)['paths'] as List),
            );
            return 'test-save';
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            null,
          );
        });
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>(
            create: (_) => ReceiptAppState(returnMode: isReturn),
            child: MaterialApp(
              home: BorrowingReceiptScreen(
                transactionId: '13',
                isReturnReceipt: isReturn,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['Save image', 'Export PDF']) {
          final previousCount = sharedFiles.length;
          await tester.tap(find.text(label));
          await tester.pump();
          for (
            var attempt = 0;
            attempt < 100 && sharedFiles.length == previousCount;
            attempt++
          ) {
            await tester.pump(const Duration(milliseconds: 30));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
          }
          await tester.pumpAndSettle();
          expect(sharedFiles.length, previousCount + 1);
          final file = File(sharedFiles.last);
          final bytes = await tester.runAsync(file.readAsBytes);
          if (label == 'Save image') {
            expect(
              file.path,
              endsWith(
                isReturn
                    ? 'TMC-return-receipt-987654321012.png'
                    : 'TMC-receipt-123456789012.png',
              ),
            );
            expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
            expect(
              ByteData.sublistView(bytes).getUint32(20),
              greaterThan(tester.view.physicalSize.height),
            );
          } else {
            expect(
              file.path,
              endsWith(
                isReturn
                    ? 'TMC-return-receipt-987654321012.pdf'
                    : 'TMC-receipt-123456789012.pdf',
              ),
            );
            expect(ascii.decode(bytes!.take(5).toList()), '%PDF-');
          }
          await tester.runAsync(file.delete);
          expect(tester.takeException(), isNull);
        }
      },
    );

    for (final brightness in Brightness.values) {
      testWidgets(
        '${isReturn ? 'return' : 'borrowing'} receipt displays QR and export controls in ${brightness.name} theme',
        (tester) async {
          await tester.pumpWidget(
            ChangeNotifierProvider<AppState>(
              create: (_) => ReceiptAppState(returnMode: isReturn),
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: BorrowingReceiptScreen(
                  transactionId: '13',
                  isReturnReceipt: isReturn,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(QrImageView), findsOneWidget);
          expect(
            find.text(isReturn ? '987654321012' : '123456789012'),
            findsOneWidget,
          );
          expect(find.text('Save image'), findsOneWidget);
          expect(find.text('Export PDF'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
