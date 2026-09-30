/// A calendar month — the unit every statistic in the app is bucketed by.
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);

  factory YearMonth.now() => YearMonth.fromDate(DateTime.now());

  final int year;
  final int month;

  YearMonth get previous =>
      month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  YearMonth get next =>
      month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);

  DateTime get firstDay => DateTime(year, month);

  /// Sortable, storage-safe form, e.g. `2026-09`.
  String get key => '$year-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(YearMonth other) =>
      year != other.year ? year.compareTo(other.year) : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
