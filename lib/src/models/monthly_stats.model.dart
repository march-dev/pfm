import 'year_month.model.dart';

/// One month of totals, all in positive integer cents.
class MonthlyStats {
  const MonthlyStats({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.cashInCents,
    required this.cashOutCents,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.transactionCount,
  });

  factory MonthlyStats.empty(YearMonth month) => MonthlyStats(
        month: month,
        incomeCents: 0,
        expenseCents: 0,
        cashInCents: 0,
        cashOutCents: 0,
        expenseByCategory: const {},
        incomeByCategory: const {},
        transactionCount: 0,
      );

  final YearMonth month;
  final int incomeCents;
  final int expenseCents;

  /// Cash movements are transfers, kept out of income/expenses (see
  /// CategoryKind.transfer).
  final int cashInCents;
  final int cashOutCents;

  /// Category id -> net spend. A refund in an expense category reduces it,
  /// so a value can be zero or (rarely) negative.
  final Map<String, int> expenseByCategory;
  final Map<String, int> incomeByCategory;
  final int transactionCount;

  int get netCents => incomeCents - expenseCents;
}
