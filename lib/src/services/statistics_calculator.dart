import '../models/category.model.dart';
import '../models/monthly_stats.model.dart';
import '../models/transaction.model.dart';
import '../models/year_month.model.dart';

/// Buckets categorized transactions into per-month totals.
///
/// Income and expenses come from category *kind*, not from the sign of each
/// amount: a refund in an expense category reduces that category's spend
/// (rather than inflating income), and cash movements — a transfer — are
/// tallied separately and never touch either total.
class StatisticsCalculator {
  const StatisticsCalculator();

  Map<YearMonth, MonthlyStats> byMonth({
    required Iterable<TransactionModel> transactions,
    required Map<String, String> categoryOf,
    required Map<String, CategoryModel> categories,
  }) {
    final builders = <YearMonth, _Builder>{};
    for (final tx in transactions) {
      final month = YearMonth.fromDate(tx.date);
      final id = categoryOf[tx.id] ?? BuiltInCategories.other;
      final kind = categories[id]?.kind ?? CategoryKind.expense;
      (builders[month] ??= _Builder(month)).add(tx, id, kind);
    }
    return {for (final e in builders.entries) e.key: e.value.build()};
  }
}

class _Builder {
  _Builder(this.month);

  final YearMonth month;
  var _income = 0;
  var _expense = 0;
  var _cashIn = 0;
  var _cashOut = 0;
  var _count = 0;
  final _expenseByCategory = <String, int>{};
  final _incomeByCategory = <String, int>{};

  void add(TransactionModel tx, String categoryId, CategoryKind kind) {
    _count++;
    switch (kind) {
      case CategoryKind.expense:
        _expense -= tx.amountCents;
        _expenseByCategory.update(
          categoryId,
          (v) => v - tx.amountCents,
          ifAbsent: () => -tx.amountCents,
        );
      case CategoryKind.income:
        _income += tx.amountCents;
        _incomeByCategory.update(
          categoryId,
          (v) => v + tx.amountCents,
          ifAbsent: () => tx.amountCents,
        );
      case CategoryKind.transfer:
        if (tx.amountCents >= 0) {
          _cashIn += tx.amountCents;
        } else {
          _cashOut -= tx.amountCents;
        }
    }
  }

  MonthlyStats build() => MonthlyStats(
        month: month,
        incomeCents: _income,
        expenseCents: _expense,
        cashInCents: _cashIn,
        cashOutCents: _cashOut,
        expenseByCategory: _expenseByCategory,
        incomeByCategory: _incomeByCategory,
        transactionCount: _count,
      );
}
