import 'package:flutter/painting.dart';
import 'package:mobx/mobx.dart';

import '../../pfm.dart';

part 'finance_state.g.dart';

class FinanceState = _FinanceStateBase with _$FinanceState;

/// The app's single source of truth for money data: every stored
/// transaction, the user's rules / assignments / custom categories, and
/// everything derived from them (each transaction's category, the
/// per-month totals).
///
/// Persistence, validation and failure reporting all live in the use cases;
/// this only mirrors the persisted data as observables and derives from it,
/// so the UI re-renders whenever any of it changes.
///
/// Registered as a plain `Provider<FinanceState>` in _RootScaffold's
/// MultiProvider (app.dart).
abstract class _FinanceStateBase with Store {
  _FinanceStateBase(
    this._transactionUseCases,
    this._categorizationUseCases,
    this._importUseCases,
  ) {
    transactions = _transactionUseCases.getAll();
    _adopt(_categorizationUseCases.load());
  }

  final TransactionsUseCases _transactionUseCases;
  final CategorizationUseCases _categorizationUseCases;
  final StatementImportUseCases _importUseCases;

  static const _statistics = StatisticsCalculator();

  @observable
  List<TransactionModel> transactions = const [];

  @observable
  List<CategoryRule> rules = const [];

  /// Transaction id -> category id, for one-off assignments.
  @observable
  Map<String, String> assignments = const {};

  @observable
  List<CategoryModel> customCategories = const [];

  @observable
  bool importing = false;

  @computed
  List<CategoryModel> get categories =>
      [...BuiltInCategories.all, ...customCategories];

  @computed
  Map<String, CategoryModel> get categoryById =>
      {for (final c in categories) c.id: c};

  /// Newest first — by booking date, then value date.
  @computed
  List<TransactionModel> get sortedTransactions => [...transactions]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        final av = a.valueDate ?? a.date;
        final bv = b.valueDate ?? b.date;
        final byValue = bv.compareTo(av);
        return byValue != 0 ? byValue : a.id.compareTo(b.id);
      });

  /// Transaction id -> the category it's currently filed under.
  @computed
  Map<String, String> get categoryOf => TransactionCategorizer(
        rules: rules,
        assignments: assignments,
        categoryIds: {for (final c in categories) c.id},
      ).categorizeAll(transactions);

  @computed
  Map<YearMonth, MonthlyStats> get statsByMonth => _statistics.byMonth(
        transactions: transactions,
        categoryOf: categoryOf,
        categories: categoryById,
      );

  /// Months that have at least one transaction, newest first.
  @computed
  List<YearMonth> get months => (statsByMonth.keys.toList()..sort())
      .reversed
      .toList();

  CategoryModel categoryFor(TransactionModel tx) =>
      categoryById[categoryOf[tx.id]] ?? BuiltInCategories.all.last;

  /// Transactions a rule of [kind] with [value] would match — the assign
  /// dialog's live "N transactions" preview, computed with the same
  /// [RuleMatcher] the categorizer uses.
  List<TransactionModel> matching(RuleKind kind, String value) {
    final predicate = const RuleMatcher().compile(kind, value);
    return predicate == null ? const [] : transactions.where(predicate).toList();
  }

  @action
  Future<ImportOutcome?> importStatement() async {
    importing = true;
    try {
      final outcome = await _importUseCases.importStatement();
      if (outcome != null) transactions = _transactionUseCases.getAll();
      return outcome;
    } finally {
      importing = false;
    }
  }

  /// [amountCents] > 0 inserts cash, < 0 withdraws it.
  @action
  Future<bool> addCashOperation({
    required DateTime date,
    required int amountCents,
    String note = '',
  }) async {
    final tx = await _transactionUseCases.addCashOperation(
      date: date,
      amountCents: amountCents,
      note: note,
    );
    if (tx == null) return false;
    transactions = [...transactions, tx];
    return true;
  }

  @action
  Future<bool> deleteTransaction(TransactionModel tx) async {
    if (!await _transactionUseCases.delete(tx)) return false;
    transactions = transactions.where((t) => t.id != tx.id).toList();
    if (assignments.containsKey(tx.id)) await clearAssignment(tx);
    return true;
  }

  @action
  Future<bool> assign({
    required TransactionModel tx,
    required String categoryId,
    required AssignmentScope scope,
    String value = '',
  }) async {
    final covered = switch (scope) {
      AssignmentScope.single => const <String>{},
      AssignmentScope.exactName => {
          for (final t in matching(RuleKind.exactName, value)) t.id,
        },
      AssignmentScope.pattern => {
          for (final t in matching(RuleKind.pattern, value)) t.id,
        },
    };
    final snapshot = await _categorizationUseCases.assign(
      transactionId: tx.id,
      categoryId: categoryId,
      scope: scope,
      value: value,
      coveredIds: covered,
    );
    if (snapshot == null) return false;
    _adopt(snapshot);
    return true;
  }

  /// Drops a one-off assignment, returning the transaction to automatic
  /// categorization.
  @action
  Future<void> clearAssignment(TransactionModel tx) async {
    final snapshot = await _categorizationUseCases.clearAssignment(tx.id);
    if (snapshot != null) _adopt(snapshot);
  }

  @action
  Future<void> deleteRule(CategoryRule rule) async {
    final snapshot = await _categorizationUseCases.deleteRule(rule.id);
    if (snapshot != null) _adopt(snapshot);
  }

  @action
  Future<bool> createCategory(String name, Color color) async {
    final snapshot = await _categorizationUseCases.createCategory(name, color);
    if (snapshot == null) return false;
    _adopt(snapshot);
    return true;
  }

  @action
  Future<void> deleteCategory(CategoryModel category) async {
    final snapshot = await _categorizationUseCases.deleteCategory(category.id);
    if (snapshot != null) _adopt(snapshot);
  }

  @action
  void _adopt(CategorizationSnapshot snapshot) {
    rules = snapshot.rules;
    assignments = snapshot.assignments;
    customCategories = snapshot.customCategories;
  }
}
