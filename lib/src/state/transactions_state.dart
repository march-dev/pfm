import 'package:mobx/mobx.dart';

import '../../pfm.dart';

part 'transactions_state.g.dart';

class TransactionsState = _TransactionsStateBase with _$TransactionsState;

enum TransactionSortBy { date, description }

/// The Transactions screen's filters and the list they produce.
abstract class _TransactionsStateBase with Store {
  _TransactionsStateBase(this._finance, this._period);

  final FinanceState _finance;
  final PeriodState _period;

  static const _merchants = MerchantNormalizer();

  @observable
  String search = '';

  /// A category id, or null for every category.
  @observable
  String? categoryFilter;

  /// Search the whole history instead of just the selected month.
  @observable
  bool allMonths = false;

  /// Newest first by default — what a statement itself looks like.
  @observable
  TransactionSortBy sortBy = TransactionSortBy.date;

  @observable
  bool sortAscending = false;

  @computed
  List<TransactionModel> get visible {
    final query = normalizeText(search);
    final categoryOf = _finance.categoryOf;
    final filtered = [
      for (final tx in _finance.transactions)
        if ((allMonths || YearMonth.fromDate(tx.date) == _period.month) &&
            (categoryFilter == null || categoryOf[tx.id] == categoryFilter) &&
            (query.isEmpty || _matchesQuery(tx, query)))
          tx,
    ];
    return _sorted(filtered);
  }

  List<TransactionModel> _sorted(List<TransactionModel> list) {
    // Whatever the primary key, ties always fall back to newest first, so
    // equal descriptions (or same-day purchases) keep a stable, sensible
    // order instead of shuffling when the direction flips.
    int newestFirst(TransactionModel a, TransactionModel b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      final byValue = (b.valueDate ?? b.date).compareTo(a.valueDate ?? a.date);
      return byValue != 0 ? byValue : a.id.compareTo(b.id);
    }

    switch (sortBy) {
      case TransactionSortBy.date:
        return list
          ..sort(
              (a, b) => sortAscending ? -newestFirst(a, b) : newestFirst(a, b));
      case TransactionSortBy.description:
        // Computed once per transaction, not per comparison.
        final keys = {
          for (final tx in list)
            tx.id: normalizeText(_merchants.merchantOf(tx.description)),
        };
        return list
          ..sort((a, b) {
            final byName = keys[a.id]!.compareTo(keys[b.id]!);
            return byName != 0
                ? (sortAscending ? byName : -byName)
                : newestFirst(a, b);
          });
    }
  }

  bool _matchesQuery(TransactionModel tx, String query) =>
      normalizeText(tx.description).contains(query) ||
      normalizeText(_merchants.merchantOf(tx.description)).contains(query);

  @action
  void setSearch(String value) => search = value;

  @action
  void setCategoryFilter(String? categoryId) => categoryFilter = categoryId;

  @action
  void setAllMonths(bool value) => allMonths = value;

  @action
  void setSort(TransactionSortBy by, {required bool ascending}) {
    sortBy = by;
    sortAscending = ascending;
  }
}
