import 'package:mobx/mobx.dart';

import '../../pfm.dart';

part 'period_state.g.dart';

class PeriodState = _PeriodStateBase with _$PeriodState;

/// Which month the Overview and Transactions screens are looking at —
/// shared, so picking September on one shows September on the other.
///
/// Until the user picks a month it follows the newest one with data, so a
/// fresh import lands them on the latest month rather than wherever they
/// last looked.
abstract class _PeriodStateBase with Store {
  _PeriodStateBase(this._finance);

  final FinanceState _finance;

  @observable
  YearMonth? selected;

  /// The month being shown: the user's pick, kept within the range that
  /// actually has data (falling back to the current calendar month when
  /// there's none yet).
  @computed
  YearMonth get month {
    final months = _finance.months;
    if (months.isEmpty) return selected ?? YearMonth.now();
    final newest = months.first;
    final oldest = months.last;
    final pick = selected ?? newest;
    if (pick.compareTo(newest) > 0) return newest;
    if (pick.compareTo(oldest) < 0) return oldest;
    return pick;
  }

  @computed
  bool get canGoPrevious {
    final months = _finance.months;
    return months.isNotEmpty && month.compareTo(months.last) > 0;
  }

  @computed
  bool get canGoNext {
    final months = _finance.months;
    return months.isNotEmpty && month.compareTo(months.first) < 0;
  }

  @action
  void select(YearMonth value) => selected = value;

  @action
  void previous() {
    if (canGoPrevious) selected = month.previous;
  }

  @action
  void next() {
    if (canGoNext) selected = month.next;
  }
}
