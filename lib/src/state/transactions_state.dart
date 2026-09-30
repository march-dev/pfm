import 'package:mobx/mobx.dart';

import '../../pfm.dart';

part 'transactions_state.g.dart';

class TransactionsState = _TransactionsStateBase with _$TransactionsState;

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

  @computed
  List<TransactionModel> get visible {
    final query = normalizeText(search);
    final categoryOf = _finance.categoryOf;
    return [
      for (final tx in _finance.sortedTransactions)
        if ((allMonths || YearMonth.fromDate(tx.date) == _period.month) &&
            (categoryFilter == null || categoryOf[tx.id] == categoryFilter) &&
            (query.isEmpty || _matchesQuery(tx, query)))
          tx,
    ];
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
}
