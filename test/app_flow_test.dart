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

  // Taps a button whose handler saves to Hive. Dispatching the tap from the
  // real zone keeps the whole async save chain on the real event loop,
  // instead of stranding its I/O callbacks in the fake-async zone.
  Future<void> tapAndSave(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() => tester.tap(finder));
    await settleIo(tester);
  }

  late DependencyResolver deps;

  Future<void> boot(WidgetTester tester, {bool seed = true}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Writes started by the UI are chains of real I/O hops whose callbacks
    // land in the test's fake-async zone; pump until they drain, or closing
    // Hive afterwards would wait on a write that can never finish.
    addTearDown(() async {
      await settleIo(tester);
      await tester.runAsync(() async {
        await Hive.close();
        dir.deleteSync(recursive: true);
      });
    });

    await tester.runAsync(() async {
      deps = await DependencyResolver.create();
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

  testWidgets('overview shows the month totals and category breakdown',
      (tester) async {
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

  testWidgets('month picker sits by the scope toggle; summary on the right',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    final toggle = tester.getRect(find.byType(SegmentedButton<bool>));
    final month = tester.getRect(find.byType(MonthSelector));
    final summary = tester.getRect(find.textContaining('40 transactions'));
    final title = tester.getRect(find.text('Transactions').last);
    final importButton = tester.getRect(find.text('Import statement').first);

    expect(month.left, greaterThanOrEqualTo(toggle.right),
        reason: 'month picker follows the segmented button');
    expect((month.center.dy - toggle.center.dy).abs(), lessThan(2),
        reason: 'same row as the segmented button');
    expect(month.top, greaterThan(title.bottom),
        reason: 'no longer in the title row');
    expect(summary.left, greaterThan(month.right),
        reason: 'summary is right of the filters');
    expect(importButton.right, greaterThan(summary.right - 40),
        reason: 'summary right-aligns with the card edge, under the buttons');

    // The picker only makes sense for a single month.
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthSelector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('column headers sort, and the Category header filters',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    // Default is newest first: the 29 Sep DIGI bill leads.
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(find.text('29/09/2026'), findsWidgets);
    final newestFirst = top('DIGI SPAIN TELECOM SA');

    // Sorting by date ascending sends it to the bottom (off screen).
    await tester.tap(find.text('DATE'));
    await tester.pumpAndSettle();
    expect(find.text('DIGI SPAIN TELECOM SA'), findsNothing,
        reason: 'oldest-first pushes the newest rows out of view');
    expect(find.text('06/09/2026'), findsWidgets);
    expect(newestFirst, lessThan(300));

    // Description sorting puts the AEAT payments first.
    await tester.tap(find.text('DESCRIPTION'));
    await tester.pumpAndSettle();
    expect(find.text('Agencia Estatal de Administracion Tributaria'),
        findsWidgets);
    final aeat = top('Agencia Estatal de Administracion Tributaria');
    await tester.tap(find.text('DESCRIPTION'));
    await tester.pumpAndSettle();
    expect(
        find.text('Agencia Estatal de Administracion Tributaria'), findsNothing,
        reason: 'descending moves A… to the end');
    expect(aeat, lessThan(300));

    // The Category column header is the filter.
    await tester.tap(find.text('CATEGORY'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Groceries'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 transactions'), findsOneWidget);
    expect(find.text('CONSUM V. F.CAT'), findsWidgets);
    expect(find.text('DIGI SPAIN TELECOM SA'), findsNothing);

    // …and clearing it brings everything back.
    await tester.tap(find.text('CATEGORY'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'All categories'));
    await tester.pumpAndSettle();
    expect(find.textContaining('40 transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the whole Category header cell opens the filter, in sort-header white',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    // Tap the far right end of the cell — nowhere near the label or icon.
    final cell = tester.getRect(find.byType(HeaderFilterButton<String>));
    expect(cell.width, greaterThan(150));
    await tester.tapAt(Offset(cell.right - 12, cell.center.dy));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MenuItemButton, 'Groceries'), findsOneWidget,
        reason: 'a tap on the empty part of the header opens the menu');

    await tester.tap(find.widgetWithText(MenuItemButton, 'Groceries'));
    await tester.pumpAndSettle();

    // Active: label and icon use the same bright color as an active sort
    // header, not the theme's primary.
    final onSurface = AppTheme.dark().colorScheme.onSurface;
    final label = tester.widget<Text>(find.text('CATEGORY'));
    expect(label.style!.color, onSurface);
    final icon = tester.widget<Icon>(find.descendant(
      of: find.byType(HeaderFilterButton<String>),
      matching: find.byIcon(Icons.filter_alt),
    ));
    expect(icon.color, onSurface);
    final sortLabel = tester.widget<Text>(find.text('DATE'));
    expect(sortLabel.style!.color, onSurface,
        reason: 'the active sort header is the reference color');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings (pinned below the rail) holds the Error Logs card',
      (tester) async {
    await boot(tester);

    // Settings sits under the divider, below the main entries.
    final settingsItem = tester.getRect(find.text('Settings'));
    final categoriesItem = tester.getRect(find.text('Categories').first);
    expect(settingsItem.top, greaterThan(categoriesItem.bottom + 100),
        reason: 'pinned to the bottom, not stacked with the others');

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Error Logs'), findsOneWidget);
    expect(deps.appSettingsRepo.getFileLoggingEnabled(), isTrue);

    // Real log file exists for this launch under <support dir>/logs.
    final logsDir = deps.errorLogRepo.logsDirectory;
    expect(logsDir.path, endsWith('logs'));
    expect(logsDir.existsSync(), isTrue);

    // The preference persists through Hive.
    await tapAndSave(tester, find.byType(Switch));
    expect(deps.appSettingsRepo.getFileLoggingEnabled(), isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assign a category to every transaction matching a pattern',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    await openTransaction(tester, 'rain forest');
    expect(find.text('Assign category'), findsOneWidget);
    expect(find.text('Just this transaction'), findsOneWidget);
    expect(
        find.text('All transactions from "RAIN FOREST VAL"'), findsOneWidget);
    expect(find.text('2 transactions'), findsOneWidget,
        reason: 'exact-name preview');

    // Pick "Groceries" in the dialog, then a pattern scope.
    await tester.tap(find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Groceries'),
    ));
    await tester.tap(find.text('All transactions matching a pattern'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'RAIN FOREST VAL'), 'rain*val');
    await tester.pumpAndSettle();
    expect(find.text('2 transactions'), findsNWidgets(2),
        reason: 'exact-name subtitle + live pattern preview');

    await tester.enterText(
        find.widgetWithText(TextField, 'rain*val'), '/(broken/');
    await tester.pumpAndSettle();
    expect(find.text('Not a valid pattern.'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, '/(broken/'), 'rain*val');
    await tester.pumpAndSettle();

    await tapAndSave(tester, find.text('Apply'));
    expect(find.text('Assign category'), findsNothing, reason: 'dialog closed');

    // Both purchases are now Groceries; the rule shows up on the rules screen.
    await tester.tap(find.text('Categories').first);
    await tester.pumpAndSettle();
    expect(find.text('rain*val'), findsOneWidget);
    expect(find.text('Pattern'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash operation dialog validates and records a withdrawal',
      (tester) async {
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
    await tester.enterText(
        find.widgetWithText(TextField, 'What was it for?'), 'Market stall');
    await tapAndSave(tester, find.text('Save'));

    expect(find.text('Cash operation'), findsOneWidget,
        reason: 'dialog closed');
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
    await tester.enterText(
        find.widgetWithText(TextField, 'Category name'), 'Pets');
    await tapAndSave(tester, find.text('Create'));

    // Back in the assign dialog with the new category present and selected.
    expect(find.text('Assign category'), findsOneWidget);
    expect(find.text('Pets'), findsOneWidget);
    await tapAndSave(tester, find.text('Apply'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every screen lays out without overflow at a small window',
      (tester) async {
    await boot(tester);
    tester.view.physicalSize = const Size(1000, 640);
    await tester.pumpAndSettle();

    for (final tab in ['Overview', 'Transactions', 'Categories', 'Settings']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab @ 1000x640');
    }
  });
}
