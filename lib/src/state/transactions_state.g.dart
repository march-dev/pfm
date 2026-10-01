// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TransactionsState on _TransactionsStateBase, Store {
  Computed<List<TransactionModel>>? _$visibleComputed;

  @override
  List<TransactionModel> get visible => (_$visibleComputed ??=
          Computed<List<TransactionModel>>(() => super.visible,
              name: '_TransactionsStateBase.visible'))
      .value;

  late final _$searchAtom =
      Atom(name: '_TransactionsStateBase.search', context: context);

  @override
  String get search {
    _$searchAtom.reportRead();
    return super.search;
  }

  @override
  set search(String value) {
    _$searchAtom.reportWrite(value, super.search, () {
      super.search = value;
    });
  }

  late final _$categoryFilterAtom =
      Atom(name: '_TransactionsStateBase.categoryFilter', context: context);

  @override
  String? get categoryFilter {
    _$categoryFilterAtom.reportRead();
    return super.categoryFilter;
  }

  @override
  set categoryFilter(String? value) {
    _$categoryFilterAtom.reportWrite(value, super.categoryFilter, () {
      super.categoryFilter = value;
    });
  }

  late final _$allMonthsAtom =
      Atom(name: '_TransactionsStateBase.allMonths', context: context);

  @override
  bool get allMonths {
    _$allMonthsAtom.reportRead();
    return super.allMonths;
  }

  @override
  set allMonths(bool value) {
    _$allMonthsAtom.reportWrite(value, super.allMonths, () {
      super.allMonths = value;
    });
  }

  late final _$sortByAtom =
      Atom(name: '_TransactionsStateBase.sortBy', context: context);

  @override
  TransactionSortBy get sortBy {
    _$sortByAtom.reportRead();
    return super.sortBy;
  }

  @override
  set sortBy(TransactionSortBy value) {
    _$sortByAtom.reportWrite(value, super.sortBy, () {
      super.sortBy = value;
    });
  }

  late final _$sortAscendingAtom =
      Atom(name: '_TransactionsStateBase.sortAscending', context: context);

  @override
  bool get sortAscending {
    _$sortAscendingAtom.reportRead();
    return super.sortAscending;
  }

  @override
  set sortAscending(bool value) {
    _$sortAscendingAtom.reportWrite(value, super.sortAscending, () {
      super.sortAscending = value;
    });
  }

  late final _$_TransactionsStateBaseActionController =
      ActionController(name: '_TransactionsStateBase', context: context);

  @override
  void setSearch(String value) {
    final _$actionInfo = _$_TransactionsStateBaseActionController.startAction(
        name: '_TransactionsStateBase.setSearch');
    try {
      return super.setSearch(value);
    } finally {
      _$_TransactionsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCategoryFilter(String? categoryId) {
    final _$actionInfo = _$_TransactionsStateBaseActionController.startAction(
        name: '_TransactionsStateBase.setCategoryFilter');
    try {
      return super.setCategoryFilter(categoryId);
    } finally {
      _$_TransactionsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAllMonths(bool value) {
    final _$actionInfo = _$_TransactionsStateBaseActionController.startAction(
        name: '_TransactionsStateBase.setAllMonths');
    try {
      return super.setAllMonths(value);
    } finally {
      _$_TransactionsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSort(TransactionSortBy by, {required bool ascending}) {
    final _$actionInfo = _$_TransactionsStateBaseActionController.startAction(
        name: '_TransactionsStateBase.setSort');
    try {
      return super.setSort(by, ascending: ascending);
    } finally {
      _$_TransactionsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
search: ${search},
categoryFilter: ${categoryFilter},
allMonths: ${allMonths},
sortBy: ${sortBy},
sortAscending: ${sortAscending},
visible: ${visible}
    ''';
  }
}
