enum TransactionSource {
  /// A row imported from a bank statement.
  bank,

  /// A cash operation the user typed in by hand.
  manualCash,
}

/// One money movement. Amounts are integer cents (never doubles) so sums
/// over a month are exact; negative is money out, positive money in.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amountCents,
    this.valueDate,
    this.balanceCents,
    this.currency = 'EUR',
    this.source = TransactionSource.bank,
  });

  /// Stable across re-imports of the same statement line (see
  /// SantanderStatementParser), which is what makes importing overlapping
  /// exports idempotent.
  final String id;

  /// The statement's "Transaction date" — the month every statistic is
  /// bucketed by, so monthly totals reconcile with the bank's own running
  /// balance.
  final DateTime date;
  final DateTime? valueDate;
  final String description;
  final int amountCents;
  final int? balanceCents;
  final String currency;
  final TransactionSource source;

  bool get isManual => source == TransactionSource.manualCash;
  bool get isIncoming => amountCents > 0;
}
