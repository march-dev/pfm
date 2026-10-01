import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pfm/l10n/generated/app_localizations_en.dart';
import 'package:pfm/pfm.dart';

class _FilePicker extends StatementPickerRepo {
  const _FilePicker(this._bytes);

  final Uint8List? _bytes;

  @override
  Future<PickedStatement?> pick() async =>
      _bytes == null ? null : PickedStatement(name: 'x.xlsx', bytes: _bytes);
}

/// A full app "session" over Hive boxes in [dir] — building a second one
/// over the same directory simulates restarting the app.
class _Session {
  _Session._(this.finance, this.period, this.overview, this.transactions);

  static Future<_Session> open(Directory dir, {Uint8List? picked}) async {
    Hive.init(dir.path);
    final settings = await Hive.openBox('settings');
    final txBox = await Hive.openBox('transactions');
    const codec = FinanceCodec();
    final txRepo = TransactionsRepo(box: txBox, codec: codec);
    final rules = RulesRepo(box: settings, codec: codec);
    final assignments = AssignmentsRepo(box: settings);
    final categories = CustomCategoriesRepo(box: settings, codec: codec);
    final l10n = AppLocalizationsEn();

    final finance = FinanceState(
      TransactionsUseCases(txRepo, l10n),
      CategorizationUseCases(rules, assignments, categories, l10n),
      StatementImportUseCases(
        _FilePicker(picked),
        const SantanderStatementParser(),
        txRepo,
        l10n,
      ),
    );
    final period = PeriodState(finance);
    return _Session._(
      finance,
      period,
      OverviewState(finance, period),
      TransactionsState(finance, period),
    );
  }

  final FinanceState finance;
  final PeriodState period;
  final OverviewState overview;
  final TransactionsState transactions;

  Future<void> close() => Hive.close();
}

void main() {
  // Failure paths report through SnackbarManager, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Uint8List statement;

  setUpAll(() {
    statement = File('test/data/TransactionExcelFile.xlsx').readAsBytesSync();
  });

  setUp(() => dir = Directory.systemTemp.createTempSync('pfm_test_'));

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  TransactionModel find(_Session s, String text) =>
      s.finance.transactions.firstWhere((t) => t.description.contains(text));

  group('import', () {
    test('imports the statement and is idempotent', () async {
      final s = await _Session.open(dir, picked: statement);
      expect(s.overview.hasData, isFalse);

      final first = await s.finance.importStatement();
      expect(first!.added, 40);
      expect(first.duplicates, 0);
      expect(s.finance.transactions, hasLength(40));

      final again = await s.finance.importStatement();
      expect(again!.added, 0);
      expect(again.duplicates, 40);
      expect(s.finance.transactions, hasLength(40), reason: 'no duplicates');
      expect(s.finance.importing, isFalse);
    });

    test('a cancelled picker or a non-statement file changes nothing',
        () async {
      final cancelled = await _Session.open(dir);
      expect(await cancelled.finance.importStatement(), isNull);

      await cancelled.close();
      final junk =
          await _Session.open(dir, picked: Uint8List.fromList([1, 2, 3]));
      expect(await junk.finance.importStatement(), isNull);
      expect(junk.finance.transactions, isEmpty);
    });

    test('lands on the newest month with September totals', () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();

      expect(s.finance.months, [const YearMonth(2026, 9)]);
      expect(s.period.month, const YearMonth(2026, 9));
      expect(s.period.canGoPrevious, isFalse);
      expect(s.period.canGoNext, isFalse);
      expect(s.overview.stats.incomeCents, 390746);
      expect(s.overview.stats.cashOutCents, 20000);
      expect(s.overview.expenseBreakdown.first.key.id, BuiltInCategories.other,
          reason:
              'rent (1.300€) is the largest single outflow, filed as other');
      expect(s.overview.history, hasLength(1));
    });
  });

  group('manual category assignment', () {
    late _Session s;

    setUp(() async {
      s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
    });

    test('scope: just this transaction', () async {
      final rainForest = s.finance.transactions
          .where((t) => t.description.contains('RAIN FOREST'))
          .toList();
      expect(rainForest, hasLength(2));

      await s.finance.assign(
        tx: rainForest.first,
        categoryId: BuiltInCategories.groceries,
        scope: AssignmentScope.single,
      );

      expect(s.finance.categoryFor(rainForest.first).id,
          BuiltInCategories.groceries);
      expect(s.finance.categoryFor(rainForest.last).id, BuiltInCategories.other,
          reason: 'the other Rain Forest purchase is untouched');
      expect(s.finance.rules, isEmpty);
    });

    test('scope: exact name applies to every purchase there', () async {
      final tx = find(s, 'RAIN FOREST');
      await s.finance.assign(
        tx: tx,
        categoryId: BuiltInCategories.groceries,
        scope: AssignmentScope.exactName,
        value: 'RAIN FOREST VAL',
      );

      for (final t in s.finance.transactions
          .where((t) => t.description.contains('RAIN FOREST'))) {
        expect(s.finance.categoryFor(t).id, BuiltInCategories.groceries);
      }
      expect(s.finance.rules.single.kind, RuleKind.exactName);
    });

    test('scope: user-written pattern', () async {
      final tx = find(s, 'Elena');
      await s.finance.assign(
        tx: tx,
        categoryId: BuiltInCategories.gifts,
        scope: AssignmentScope.pattern,
        value: 'transferencia inmediata*sukhonosova',
      );
      final elena = s.finance.transactions
          .where((t) => t.description.contains('Sukhonosova'));
      expect(elena, hasLength(3));
      expect(elena.map((t) => s.finance.categoryFor(t).id).toSet(),
          {BuiltInCategories.gifts});
      expect(s.overview.stats.expenseByCategory[BuiltInCategories.gifts],
          2000 + 1000 + 10000);
    });

    test('an invalid pattern is rejected and saves nothing', () async {
      final ok = await s.finance.assign(
        tx: find(s, 'Elena'),
        categoryId: BuiltInCategories.gifts,
        scope: AssignmentScope.pattern,
        value: '/(broken/',
      );
      expect(ok, isFalse);
      expect(s.finance.rules, isEmpty);
    });

    test('a new rule supersedes earlier one-off assignments it covers',
        () async {
      final rf = s.finance.transactions
          .where((t) => t.description.contains('RAIN FOREST'))
          .toList();
      await s.finance.assign(
        tx: rf.first,
        categoryId: BuiltInCategories.health,
        scope: AssignmentScope.single,
      );
      await s.finance.assign(
        tx: rf.first,
        categoryId: BuiltInCategories.groceries,
        scope: AssignmentScope.exactName,
        value: 'RAIN FOREST VAL',
      );
      expect(s.finance.categoryFor(rf.first).id, BuiltInCategories.groceries,
          reason: 'the newest instruction wins, not the stale one-off');
      expect(s.finance.assignments, isEmpty);
    });

    test('re-applying the same rule replaces it rather than duplicating',
        () async {
      final tx = find(s, 'RAIN FOREST');
      for (final category in [
        BuiltInCategories.groceries,
        BuiltInCategories.gifts
      ]) {
        await s.finance.assign(
          tx: tx,
          categoryId: category,
          scope: AssignmentScope.exactName,
          value: 'rain forest val',
        );
      }
      expect(s.finance.rules, hasLength(1));
      expect(s.finance.categoryFor(tx).id, BuiltInCategories.gifts);
    });

    test('clearing an assignment returns to automatic categorization',
        () async {
      final tx = find(s, 'CONSUM');
      await s.finance.assign(
          tx: tx,
          categoryId: BuiltInCategories.gifts,
          scope: AssignmentScope.single);
      expect(s.finance.categoryFor(tx).id, BuiltInCategories.gifts);
      await s.finance.clearAssignment(tx);
      expect(s.finance.categoryFor(tx).id, BuiltInCategories.groceries);
    });

    test('deleting a rule undoes it', () async {
      final tx = find(s, 'RAIN FOREST');
      await s.finance.assign(
        tx: tx,
        categoryId: BuiltInCategories.groceries,
        scope: AssignmentScope.exactName,
        value: 'RAIN FOREST VAL',
      );
      await s.finance.deleteRule(s.finance.rules.single);
      expect(s.finance.categoryFor(tx).id, BuiltInCategories.other);
    });

    test('reassigning changes the month statistics', () async {
      final before =
          s.overview.stats.expenseByCategory[BuiltInCategories.groceries]!;
      final tx = find(s, 'RAIN FOREST');
      await s.finance.assign(
          tx: tx,
          categoryId: BuiltInCategories.groceries,
          scope: AssignmentScope.single);
      expect(s.overview.stats.expenseByCategory[BuiltInCategories.groceries],
          before + tx.amountCents.abs());
    });
  });

  group('custom categories', () {
    test('create, use, reject duplicates, delete cleans up', () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();

      expect(
          await s.finance
              .createCategory('Rent', AppColors.categoryPalette.first),
          isTrue);
      final rent = s.finance.customCategories.single;
      expect(rent.name, 'Rent');

      expect(
          await s.finance
              .createCategory('rent', AppColors.categoryPalette.first),
          isFalse);
      expect(
          await s.finance
              .createCategory('groceries', AppColors.categoryPalette.first),
          isFalse,
          reason: 'clashes with a built-in name');
      expect(
          await s.finance
              .createCategory('   ', AppColors.categoryPalette.first),
          isFalse);

      final tx = find(s, 'Renta Septiembre');
      await s.finance.assign(
        tx: tx,
        categoryId: rent.id,
        scope: AssignmentScope.pattern,
        value: 'renta',
      );
      expect(s.finance.categoryFor(tx).id, rent.id);
      expect(s.overview.stats.expenseByCategory[rent.id], 130000);

      await s.finance.deleteCategory(rent);
      expect(s.finance.customCategories, isEmpty);
      expect(s.finance.rules, isEmpty);
      expect(s.finance.categoryFor(tx).id, BuiltInCategories.other);
    });
  });

  group('cash operations', () {
    test('insert and withdraw are filed under Cash and stay out of the totals',
        () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      final expensesBefore = s.overview.stats.expenseCents;
      final incomeBefore = s.overview.stats.incomeCents;

      await s.finance
          .addCashOperation(date: DateTime(2026, 9, 20), amountCents: 5000);
      await s.finance.addCashOperation(
          date: DateTime(2026, 9, 21), amountCents: -1250, note: 'Market');

      final stats = s.overview.stats;
      expect(stats.cashInCents, 5000);
      expect(stats.cashOutCents, 20000 + 1250);
      expect(stats.expenseCents, expensesBefore);
      expect(stats.incomeCents, incomeBefore);

      final withdrawn = find(s, 'Market');
      expect(withdrawn.isManual, isTrue);
      expect(s.finance.categoryFor(withdrawn).id, BuiltInCategories.cash);
      expect(find(s, 'Cash inserted').amountCents, 5000);
    });

    test('a cash withdrawal re-filed as spending counts as an expense',
        () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      final before = s.overview.stats.expenseCents;

      await s.finance.addCashOperation(
          date: DateTime(2026, 9, 21),
          amountCents: -350,
          note: 'Coffee in cash');
      final coffee = find(s, 'Coffee in cash');
      await s.finance.assign(
          tx: coffee,
          categoryId: BuiltInCategories.cafeResto,
          scope: AssignmentScope.single);

      expect(s.overview.stats.expenseCents, before + 350);
    });

    test('deleting a manual operation removes it and its assignment', () async {
      final s = await _Session.open(dir);
      await s.finance.addCashOperation(
          date: DateTime(2026, 9, 21), amountCents: -350, note: 'x');
      final tx = s.finance.transactions.single;
      await s.finance.assign(
          tx: tx,
          categoryId: BuiltInCategories.gifts,
          scope: AssignmentScope.single);

      expect(await s.finance.deleteTransaction(tx), isTrue);
      expect(s.finance.transactions, isEmpty);
      expect(s.finance.assignments, isEmpty);
    });
  });

  group('persistence', () {
    test('everything survives an app restart', () async {
      final first = await _Session.open(dir, picked: statement);
      await first.finance.importStatement();
      await first.finance.createCategory('Rent', AppColors.categoryPalette[2]);
      final rentId = first.finance.customCategories.single.id;
      await first.finance.assign(
        tx: find(first, 'Renta Septiembre'),
        categoryId: rentId,
        scope: AssignmentScope.pattern,
        value: 'renta',
      );
      await first.finance.assign(
        tx: find(first, 'CONSUM'),
        categoryId: BuiltInCategories.gifts,
        scope: AssignmentScope.single,
      );
      await first.finance.addCashOperation(
          date: DateTime(2026, 9, 2), amountCents: 700, note: 'Found');
      final expected = first.overview.stats;
      await first.close();

      final second = await _Session.open(dir);
      expect(second.finance.transactions, hasLength(41));
      expect(second.finance.rules.single.value, 'renta');
      expect(second.finance.customCategories.single.color,
          AppColors.categoryPalette[2]);
      expect(second.finance.assignments, hasLength(1));

      final stats = second.overview.stats;
      expect(stats.incomeCents, expected.incomeCents);
      expect(stats.expenseCents, expected.expenseCents);
      expect(stats.cashInCents, expected.cashInCents);
      expect(stats.expenseByCategory, expected.expenseByCategory);
    });
  });

  group('transactions screen state', () {
    test('filters by month, category and search', () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      await s.finance.addCashOperation(
          date: DateTime(2026, 8, 30), amountCents: 100, note: 'August');

      expect(s.transactions.visible, hasLength(40), reason: 'September only');
      s.transactions.setAllMonths(true);
      expect(s.transactions.visible, hasLength(41));
      s.transactions.setAllMonths(false);

      s.transactions.setCategoryFilter(BuiltInCategories.groceries);
      expect(s.transactions.visible, hasLength(3));
      s.transactions.setCategoryFilter(null);

      s.transactions.setSearch('  FARMÁCIA  ');
      expect(s.transactions.visible.single.description, contains('FARMACIA'));
      s.transactions.setSearch('elena sukhonosova');
      expect(s.transactions.visible, hasLength(3),
          reason: 'matches the merchant name');
      s.transactions.setSearch('');

      s.period.previous();
      expect(s.period.month, const YearMonth(2026, 8));
      expect(s.transactions.visible.single.description, 'August');
      expect(s.period.canGoNext, isTrue);
    });

    test('sorts by date either way, and by description with stable ties',
        () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      s.transactions.setAllMonths(true);

      // Default: newest first.
      expect(s.transactions.sortBy, TransactionSortBy.date);
      expect(s.transactions.sortAscending, isFalse);
      var dates = s.transactions.visible.map((t) => t.date).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));

      s.transactions.setSort(TransactionSortBy.date, ascending: true);
      dates = s.transactions.visible.map((t) => t.date).toList();
      expect(dates, [...dates]..sort());
      expect(dates.first, DateTime(2026, 9, 6));

      const merchants = MerchantNormalizer();
      String name(TransactionModel t) =>
          normalizeText(merchants.merchantOf(t.description));

      s.transactions.setSort(TransactionSortBy.description, ascending: true);
      var names = s.transactions.visible.map(name).toList();
      expect(names, [...names]..sort());
      expect(names.first, 'agencia estatal de administracion tributaria');

      s.transactions.setSort(TransactionSortBy.description, ascending: false);
      names = s.transactions.visible.map(name).toList();
      expect(names, [...names]..sort((a, b) => b.compareTo(a)));

      // Equal descriptions stay newest-first in both directions.
      for (final ascending in [true, false]) {
        s.transactions
            .setSort(TransactionSortBy.description, ascending: ascending);
        final orders = s.transactions.visible
            .where((t) => name(t) == 'order from restaurant')
            .map((t) => t.date)
            .toList();
        expect(orders, [...orders]..sort((a, b) => b.compareTo(a)),
            reason: 'ties, ascending=$ascending');
      }
    });

    test('sorting applies after filtering', () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      s.transactions.setCategoryFilter(BuiltInCategories.groceries);
      s.transactions.setSort(TransactionSortBy.date, ascending: true);
      final dates = s.transactions.visible.map((t) => t.date).toList();
      expect(dates, hasLength(3));
      expect(dates, [...dates]..sort());
    });

    test('newest transactions come first', () async {
      final s = await _Session.open(dir, picked: statement);
      await s.finance.importStatement();
      final dates = s.transactions.visible.map((t) => t.date).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    });
  });
}
