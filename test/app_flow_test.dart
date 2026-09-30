import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pfm/pfm.dart';

/// Boots the real App over a real (temp-dir) Hive database seeded from the
/// sample Santander export, and drives it like a user would.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pfm_ui_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> boot(WidgetTester tester, {bool seed = true}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final deps = await DependencyResolver.create();
      if (seed) {
        final parsed = const SantanderStatementParser().parse(
          File('test/data/TransactionExcelFile.xlsx').readAsBytesSync(),
        );
        await deps.transactionsRepo.addNew(parsed.transactions);
      }
      runApp(App(dependencies: deps));
    });
    await tester.pumpAndSettle();
  }

  // Hive does real disk I/O, but widget tests run in fake-async: a save
  // that awaits several writes in a row only advances one step per real-time
  // wait. So alternate short real waits with frame pumps until it drains.
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  // The table only builds rows near the viewport, so narrow it down with the
  // search box first, then open the first hit's assign dialog.
  Future<void> openTransaction(WidgetTester tester, String search) async {
    await tester.enterText(find.byType(TextField).first, search);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CategoryChip).first);
    await tester.pumpAndSettle();
  }

  testWidgets('empty state invites an import', (tester) async {
    await boot(tester, seed: false);

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Import statement'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview shows the month totals and category breakdown', (tester) async {
    await boot(tester);

    expect(find.text('September 2026'), findsWidgets);
    expect(find.text('3.907,46€'), findsWidgets, reason: 'income');
    expect(find.text('Cafes & restaurants'), findsWidgets);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Utility bills'), findsWidgets);
    expect(find.text('Taxes'), findsWidgets);
    expect(find.textContaining('Cash: 200,00€ taken out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transactions list, search and category filter', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    expect(find.text('DIGI SPAIN TELECOM SA'), findsOneWidget);
    expect(find.text('40 transactions · -2.011,62€'), findsNothing);
    expect(find.textContaining('40 transactions'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'farmacia');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 transaction'), findsOneWidget);
    expect(find.text('FARMACIA ANDRES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assign a category to every transaction matching a pattern', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    await openTransaction(tester, 'rain forest');
    expect(find.text('Assign category'), findsOneWidget);
    expect(find.text('Just this transaction'), findsOneWidget);
    expect(find.text('All transactions from "RAIN FOREST VAL"'), findsOneWidget);
    expect(find.text('2 transactions'), findsOneWidget, reason: 'exact-name preview');

    // Pick "Groceries" in the dialog, then a pattern scope.
    await tester.tap(find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Groceries'),
    ));
    await tester.tap(find.text('All transactions matching a pattern'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'RAIN FOREST VAL'), 'rain*val');
    await tester.pumpAndSettle();
    expect(find.text('2 transactions'), findsNWidgets(2),
        reason: 'exact-name subtitle + live pattern preview');

    await tester.enterText(find.widgetWithText(TextField, 'rain*val'), '/(broken/');
    await tester.pumpAndSettle();
    expect(find.text('Not a valid pattern.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '/(broken/'), 'rain*val');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await settleIo(tester);
    expect(find.text('Assign category'), findsNothing, reason: 'dialog closed');

    // Both purchases are now Groceries; the rule shows up on the rules screen.
    await tester.tap(find.text('Categories').first);
    await tester.pumpAndSettle();
    expect(find.text('rain*val'), findsOneWidget);
    expect(find.text('Pattern'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash operation dialog validates and records a withdrawal', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cash operation'));
    await tester.pumpAndSettle();
    expect(find.text('Insert cash'), findsOneWidget);
    expect(find.text('Withdraw cash'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);

    await tester.tap(find.text('Withdraw cash'));
    await tester.enterText(find.widgetWithText(TextField, '0,00'), '12,50');
    await tester.enterText(find.widgetWithText(TextField, 'What was it for?'), 'Market stall');
    await tester.tap(find.text('Save'));
    await settleIo(tester);

    expect(find.text('Cash operation'), findsOneWidget, reason: 'dialog closed');
    await tester.enterText(find.byType(TextField).first, 'market');
    await tester.pumpAndSettle();
    expect(find.text('Market stall'), findsWidgets);
    expect(find.text('-12,50€'), findsOneWidget);
    expect(find.text('Cash'), findsWidgets, reason: 'filed under Cash');
    expect(tester.takeException(), isNull);
  });

  testWidgets('new category from the assign dialog', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();
    await openTransaction(tester, 'rain forest');

    await tester.tap(find.text('New category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Category name'), 'Pets');
    await tester.tap(find.text('Create'));
    await settleIo(tester);

    // Back in the assign dialog with the new category present and selected.
    expect(find.text('Assign category'), findsOneWidget);
    expect(find.text('Pets'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await settleIo(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every screen lays out without overflow at a small window', (tester) async {
    await boot(tester);
    tester.view.physicalSize = const Size(1000, 640);
    await tester.pumpAndSettle();

    for (final tab in ['Overview', 'Transactions', 'Categories']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab @ 1000x640');
    }
  });
}
