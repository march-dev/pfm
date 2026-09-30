// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FinanceState on _FinanceStateBase, Store {
  Computed<List<CategoryModel>>? _$categoriesComputed;

  @override
  List<CategoryModel> get categories => (_$categoriesComputed ??=
          Computed<List<CategoryModel>>(() => super.categories,
              name: '_FinanceStateBase.categories'))
      .value;
  Computed<Map<String, CategoryModel>>? _$categoryByIdComputed;

  @override
  Map<String, CategoryModel> get categoryById => (_$categoryByIdComputed ??=
          Computed<Map<String, CategoryModel>>(() => super.categoryById,
              name: '_FinanceStateBase.categoryById'))
      .value;
  Computed<List<TransactionModel>>? _$sortedTransactionsComputed;

  @override
  List<TransactionModel> get sortedTransactions =>
      (_$sortedTransactionsComputed ??= Computed<List<TransactionModel>>(
              () => super.sortedTransactions,
              name: '_FinanceStateBase.sortedTransactions'))
          .value;
  Computed<Map<String, String>>? _$categoryOfComputed;

  @override
  Map<String, String> get categoryOf => (_$categoryOfComputed ??=
          Computed<Map<String, String>>(() => super.categoryOf,
              name: '_FinanceStateBase.categoryOf'))
      .value;
  Computed<Map<YearMonth, MonthlyStats>>? _$statsByMonthComputed;

  @override
  Map<YearMonth, MonthlyStats> get statsByMonth => (_$statsByMonthComputed ??=
          Computed<Map<YearMonth, MonthlyStats>>(() => super.statsByMonth,
              name: '_FinanceStateBase.statsByMonth'))
      .value;
  Computed<List<YearMonth>>? _$monthsComputed;

  @override
  List<YearMonth> get months =>
      (_$monthsComputed ??= Computed<List<YearMonth>>(() => super.months,
              name: '_FinanceStateBase.months'))
          .value;

  late final _$transactionsAtom =
      Atom(name: '_FinanceStateBase.transactions', context: context);

  @override
  List<TransactionModel> get transactions {
    _$transactionsAtom.reportRead();
    return super.transactions;
  }

  @override
  set transactions(List<TransactionModel> value) {
    _$transactionsAtom.reportWrite(value, super.transactions, () {
      super.transactions = value;
    });
  }

  late final _$rulesAtom =
      Atom(name: '_FinanceStateBase.rules', context: context);

  @override
  List<CategoryRule> get rules {
    _$rulesAtom.reportRead();
    return super.rules;
  }

  @override
  set rules(List<CategoryRule> value) {
    _$rulesAtom.reportWrite(value, super.rules, () {
      super.rules = value;
    });
  }

  late final _$assignmentsAtom =
      Atom(name: '_FinanceStateBase.assignments', context: context);

  @override
  Map<String, String> get assignments {
    _$assignmentsAtom.reportRead();
    return super.assignments;
  }

  @override
  set assignments(Map<String, String> value) {
    _$assignmentsAtom.reportWrite(value, super.assignments, () {
      super.assignments = value;
    });
  }

  late final _$customCategoriesAtom =
      Atom(name: '_FinanceStateBase.customCategories', context: context);

  @override
  List<CategoryModel> get customCategories {
    _$customCategoriesAtom.reportRead();
    return super.customCategories;
  }

  @override
  set customCategories(List<CategoryModel> value) {
    _$customCategoriesAtom.reportWrite(value, super.customCategories, () {
      super.customCategories = value;
    });
  }

  late final _$importingAtom =
      Atom(name: '_FinanceStateBase.importing', context: context);

  @override
  bool get importing {
    _$importingAtom.reportRead();
    return super.importing;
  }

  @override
  set importing(bool value) {
    _$importingAtom.reportWrite(value, super.importing, () {
      super.importing = value;
    });
  }

  late final _$importStatementAsyncAction =
      AsyncAction('_FinanceStateBase.importStatement', context: context);

  @override
  Future<ImportOutcome?> importStatement() {
    return _$importStatementAsyncAction.run(() => super.importStatement());
  }

  late final _$addCashOperationAsyncAction =
      AsyncAction('_FinanceStateBase.addCashOperation', context: context);

  @override
  Future<bool> addCashOperation(
      {required DateTime date, required int amountCents, String note = ''}) {
    return _$addCashOperationAsyncAction.run(() => super
        .addCashOperation(date: date, amountCents: amountCents, note: note));
  }

  late final _$deleteTransactionAsyncAction =
      AsyncAction('_FinanceStateBase.deleteTransaction', context: context);

  @override
  Future<bool> deleteTransaction(TransactionModel tx) {
    return _$deleteTransactionAsyncAction
        .run(() => super.deleteTransaction(tx));
  }

  late final _$assignAsyncAction =
      AsyncAction('_FinanceStateBase.assign', context: context);

  @override
  Future<bool> assign(
      {required TransactionModel tx,
      required String categoryId,
      required AssignmentScope scope,
      String value = ''}) {
    return _$assignAsyncAction.run(() => super
        .assign(tx: tx, categoryId: categoryId, scope: scope, value: value));
  }

  late final _$clearAssignmentAsyncAction =
      AsyncAction('_FinanceStateBase.clearAssignment', context: context);

  @override
  Future<void> clearAssignment(TransactionModel tx) {
    return _$clearAssignmentAsyncAction.run(() => super.clearAssignment(tx));
  }

  late final _$deleteRuleAsyncAction =
      AsyncAction('_FinanceStateBase.deleteRule', context: context);

  @override
  Future<void> deleteRule(CategoryRule rule) {
    return _$deleteRuleAsyncAction.run(() => super.deleteRule(rule));
  }

  late final _$createCategoryAsyncAction =
      AsyncAction('_FinanceStateBase.createCategory', context: context);

  @override
  Future<bool> createCategory(String name, Color color) {
    return _$createCategoryAsyncAction
        .run(() => super.createCategory(name, color));
  }

  late final _$deleteCategoryAsyncAction =
      AsyncAction('_FinanceStateBase.deleteCategory', context: context);

  @override
  Future<void> deleteCategory(CategoryModel category) {
    return _$deleteCategoryAsyncAction
        .run(() => super.deleteCategory(category));
  }

  late final _$_FinanceStateBaseActionController =
      ActionController(name: '_FinanceStateBase', context: context);

  @override
  void _adopt(CategorizationSnapshot snapshot) {
    final _$actionInfo = _$_FinanceStateBaseActionController.startAction(
        name: '_FinanceStateBase._adopt');
    try {
      return super._adopt(snapshot);
    } finally {
      _$_FinanceStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
transactions: ${transactions},
rules: ${rules},
assignments: ${assignments},
customCategories: ${customCategories},
importing: ${importing},
categories: ${categories},
categoryById: ${categoryById},
sortedTransactions: ${sortedTransactions},
categoryOf: ${categoryOf},
statsByMonth: ${statsByMonth},
months: ${months}
    ''';
  }
}
