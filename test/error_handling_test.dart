import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/l10n/generated/app_localizations_en.dart';
import 'package:pfm/pfm.dart';

// --- fakes: every repo operation fails, like a full / read-only disk ---

class _PickerReturning extends StatementPickerRepo {
  const _PickerReturning(this._file, {this.throws = false});

  final PickedStatement? _file;
  final bool throws;

  @override
  Future<PickedStatement?> pick() async {
    if (throws) throw const FileSystemException('permission denied');
    return _file;
  }
}

class _BrokenTransactions implements TransactionsRepo {
  @override
  List<TransactionModel> getAll() => throw StateError('read failed');

  @override
  Future<int> addNew(Iterable<TransactionModel> transactions) =>
      throw StateError('write failed');

  @override
  Future<void> delete(String id) => throw StateError('delete failed');
}

class _BrokenRules implements RulesRepo {
  @override
  List<CategoryRule> getAll() => throw StateError('read failed');

  @override
  Future<void> saveAll(List<CategoryRule> rules) =>
      throw StateError('write failed');
}

class _BrokenAssignments implements AssignmentsRepo {
  @override
  Map<String, String> getAll() => throw StateError('read failed');

  @override
  Future<void> saveAll(Map<String, String> assignments) =>
      throw StateError('write failed');
}

class _BrokenCategories implements CustomCategoriesRepo {
  @override
  List<CategoryModel> getAll() => throw StateError('read failed');

  @override
  Future<void> saveAll(List<CategoryModel> categories) =>
      throw StateError('write failed');
}

void main() {
  final l10n = AppLocalizationsEn();
  late Directory dir;
  late File logFile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pfm_errors_test_');
  });

  tearDown(() {
    setFileLoggingEnabled(false);
    dir.deleteSync(recursive: true);
  });

  /// The app shell the snackbar needs: a Navigator registered on
  /// SnackbarManager.navigatorKey, exactly as App does — plus a real
  /// per-launch log file, so we can check errors are recorded too.
  Future<void> pumpHost(WidgetTester tester) async {
    logFile = (await tester.runAsync(
      () => initSessionLogFile(
        Directory('${dir.path}/logs'),
        DateTime(2026, 10, 2),
        enabled: true,
      ),
    ))!;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: SnackbarManager.navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }

  // Lets the toast's 3s auto-dismiss timer run out so no snackbar leaks into
  // the next test (SnackbarManager keeps its current entry in a static).
  Future<void> dismiss(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 4));

  Color toastColor(WidgetTester tester, String message) {
    final bubble = find
        .ancestor(of: find.text(message), matching: find.byType(Container))
        .first;
    final decoration =
        tester.widget<Container>(bubble).decoration! as BoxDecoration;
    return decoration.color!;
  }

  String log() => logFile.readAsStringSync();

  group('use cases: a failure shows a snackbar, returns safely, and is logged',
      () {
    testWidgets('import: the file picker itself fails', (tester) async {
      await pumpHost(tester);
      final useCases = StatementImportUseCases(
        const _PickerReturning(null, throws: true),
        const SantanderStatementParser(),
        _BrokenTransactions(),
        l10n,
      );

      expect(await useCases.importStatement(), isNull);
      await tester.pump();

      expect(find.text("Couldn't import that file."), findsOneWidget);
      expect(toastColor(tester, "Couldn't import that file."), Colors.orange,
          reason: 'problems use the default orange');
      expect(log(), contains('Import statement'));
      expect(log(), contains('permission denied'));
      await dismiss(tester);
    });

    testWidgets('import: not a Santander export', (tester) async {
      await pumpHost(tester);
      final useCases = StatementImportUseCases(
        _PickerReturning(
          PickedStatement(name: 'x.xlsx', bytes: Uint8List.fromList([1, 2, 3])),
        ),
        const SantanderStatementParser(),
        _BrokenTransactions(),
        l10n,
      );

      expect(await useCases.importStatement(), isNull);
      await tester.pump();

      expect(
        find.text(
            "That file doesn't look like a Santander account activity export."),
        findsOneWidget,
      );
      expect(log(), contains('unrecognised format'));
      await dismiss(tester);
    });

    testWidgets('import: cancelling the picker is silent', (tester) async {
      await pumpHost(tester);
      final useCases = StatementImportUseCases(
        const _PickerReturning(null),
        const SantanderStatementParser(),
        _BrokenTransactions(),
        l10n,
      );

      expect(await useCases.importStatement(), isNull);
      await tester.pump();
      expect(
          find
              .byType(IgnorePointer)
              .evaluate()
              .where((e) => find
                  .descendant(
                      of: find.byWidget(e.widget), matching: find.byType(Text))
                  .evaluate()
                  .isNotEmpty)
              .isEmpty,
          isTrue);
      expect(logFile.existsSync(), isFalse,
          reason: 'not an error, nothing logged');
    });

    testWidgets('transactions: load, add cash, delete', (tester) async {
      await pumpHost(tester);
      final useCases = TransactionsUseCases(_BrokenTransactions(), l10n);

      expect(useCases.getAll(), isEmpty);
      await tester.pump();
      expect(find.text("Couldn't load your saved data."), findsOneWidget);

      expect(
        await useCases.addCashOperation(
            date: DateTime(2026, 9, 1), amountCents: -500),
        isNull,
      );
      await tester.pump();
      expect(find.text("Couldn't save the cash operation."), findsOneWidget);
      expect(find.text("Couldn't load your saved data."), findsNothing,
          reason: 'a new message replaces the old one, never stacks');

      final tx = TransactionModel(
        id: 'a',
        date: DateTime(2026, 9, 1),
        description: 'x',
        amountCents: -1,
      );
      expect(await useCases.delete(tx), isFalse);
      await tester.pump();
      expect(find.text("Couldn't delete the transaction."), findsOneWidget);

      expect(log(), contains('Load transactions'));
      expect(log(), contains('Add cash operation'));
      expect(log(), contains('Delete transaction "x"'));
      await dismiss(tester);
    });

    testWidgets('categorization: save failures and validation', (tester) async {
      await pumpHost(tester);
      final useCases = CategorizationUseCases(
        _BrokenRules(),
        _BrokenAssignments(),
        _BrokenCategories(),
        l10n,
      );

      final snapshot = useCases.load();
      expect(snapshot.rules, isEmpty);
      await tester.pump();
      expect(find.text("Couldn't load your saved data."), findsOneWidget);

      expect(
        await useCases.assign(
          transactionId: 't',
          categoryId: BuiltInCategories.gifts,
          scope: AssignmentScope.single,
        ),
        isNull,
      );
      await tester.pump();
      expect(find.text("Couldn't save the category."), findsOneWidget);

      // Validation (not a storage failure) has its own, specific message.
      expect(
        await useCases.assign(
          transactionId: 't',
          categoryId: BuiltInCategories.gifts,
          scope: AssignmentScope.pattern,
          value: '/(broken/',
        ),
        isNull,
      );
      await tester.pump();
      expect(find.text("That pattern isn't valid."), findsOneWidget);

      expect(await useCases.deleteRule('r'), isNull);
      await tester.pump();
      expect(find.text("Couldn't update the rules."), findsOneWidget);
      expect(log(), contains('Assign category'));
      expect(log(), contains('Delete rule'));
      await dismiss(tester);
    });

    testWidgets('a clean import is green, not orange', (tester) async {
      await pumpHost(tester);
      SnackbarManager.showSuccess('Imported 40 new transactions.');
      await tester.pump();
      expect(toastColor(tester, 'Imported 40 new transactions.'),
          AppColors.success);
      await dismiss(tester);
    });
  });

  group('snackbar behaviour', () {
    testWidgets('dismisses itself after 3 seconds', (tester) async {
      await pumpHost(tester);
      SnackbarManager.show('hello');
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('hello'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('hello'), findsNothing);
    });

    testWidgets('a stale timer never removes a newer message', (tester) async {
      await pumpHost(tester);
      SnackbarManager.show('first');
      await tester.pump(const Duration(seconds: 2));
      SnackbarManager.show('second');
      await tester.pump(const Duration(seconds: 2)); // first's timer fires
      expect(find.text('second'), findsOneWidget);
      await dismiss(tester);
    });

    testWidgets('before the app is mounted it is a harmless no-op',
        (tester) async {
      expect(() => SnackbarManager.show('too early'), returnsNormally);
    });
  });

  group('global handler: errors nobody caught', () {
    // installGlobalErrorHandlers replaces process-wide hooks; put the test
    // framework's own back afterwards.
    late FlutterExceptionHandler? originalFlutterOnError;
    late ErrorCallback? originalPlatformOnError;

    setUp(() {
      originalFlutterOnError = FlutterError.onError;
      originalPlatformOnError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = originalFlutterOnError;
      PlatformDispatcher.instance.onError = originalPlatformOnError;
    });

    testWidgets('an uncaught async error shows the generic message',
        (tester) async {
      await pumpHost(tester);
      installGlobalErrorHandlers();

      final handled = PlatformDispatcher.instance.onError!(
        StateError('stray future'),
        StackTrace.current,
      );
      await tester.pump();

      expect(handled, isTrue,
          reason: 'reported as handled, so the app survives');
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(log(), contains('Uncaught async error'));
      expect(log(), contains('stray future'));
      await dismiss(tester);
    });

    testWidgets('an uncaught framework error shows it and logs it',
        (tester) async {
      await pumpHost(tester);
      installGlobalErrorHandlers();

      FlutterError.onError!(
        FlutterErrorDetails(exception: Exception('layout blew up')),
      );
      // The previous handler (the test framework's) also records it as a
      // pending test exception — consume that, it's expected here.
      expect(tester.takeException(), isNotNull);
      await tester.pump();

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(log(), contains('Uncaught framework error'));
      expect(log(), contains('layout blew up'));
      await dismiss(tester);
    });

    testWidgets('the benign macOS key-tracking assertion stays quiet',
        (tester) async {
      await pumpHost(tester);
      installGlobalErrorHandlers();

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: AssertionError(
            'A KeyDownEvent is dispatched, but the physical key is already pressed.',
          ),
        ),
      );
      expect(tester.takeException(), isNotNull);
      await tester.pump();

      expect(find.text('Something went wrong.'), findsNothing,
          reason: 'logged for visibility, but no alarming snackbar');
      expect(log(), contains('physical key is already pressed'));
    });
  });
}
