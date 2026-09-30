import 'package:mobx/mobx.dart';

import '../../pfm.dart';

part 'overview_state.g.dart';

class OverviewState = _OverviewStateBase with _$OverviewState;

/// What the Overview screen shows for the selected month.
abstract class _OverviewStateBase with Store {
  _OverviewStateBase(this._finance, this._period);

  final FinanceState _finance;
  final PeriodState _period;

  static const historyLength = 12;

  @computed
  MonthlyStats get stats =>
      _finance.statsByMonth[_period.month] ?? MonthlyStats.empty(_period.month);

  /// Expense categories with something spent this month, largest first.
  @computed
  List<MapEntry<CategoryModel, int>> get expenseBreakdown {
    final entries = <MapEntry<CategoryModel, int>>[
      for (final e in stats.expenseByCategory.entries)
        if (e.value > 0 && _finance.categoryById[e.key] != null)
          MapEntry(_finance.categoryById[e.key]!, e.value),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Up to [historyLength] months of totals, newest first, for the trend
  /// table.
  @computed
  List<MonthlyStats> get history => [
        for (final month in _finance.months.take(historyLength))
          _finance.statsByMonth[month]!,
      ];

  @computed
  bool get hasData => _finance.transactions.isNotEmpty;
}
