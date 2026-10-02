// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PFM';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navCategories => 'Categories';

  @override
  String get categoryCafeResto => 'Cafes & restaurants';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryBeauty => 'Beauty';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryUtilities => 'Utility bills';

  @override
  String get categoryTaxes => 'Taxes';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categoryCash => 'Cash';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categoryOther => 'Other';

  @override
  String get overviewTitle => 'Overview';

  @override
  String get statIncome => 'Income';

  @override
  String get statExpenses => 'Expenses';

  @override
  String get statNet => 'Net';

  @override
  String get statCashOut => 'Cash out';

  @override
  String get statCashIn => 'Cash in';

  @override
  String get overviewEmptyTitle => 'No transactions yet';

  @override
  String get overviewEmptyMessage =>
      'Import an account activity export (.xlsx) from Santander to see your monthly income and spending.';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get nothingSpentTitle => 'Nothing spent this month';

  @override
  String get nothingSpentMessage => 'No expenses were recorded in this month.';

  @override
  String cashNote(String out, String inn) {
    return 'Cash: $out taken out, $inn put in — moves of money, not counted as spending.';
  }

  @override
  String get columnMonth => 'Month';

  @override
  String get historyEmpty => 'No months yet.';

  @override
  String get importStatement => 'Import statement';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new transactions',
      one: '1 new transaction',
    );
    return 'Imported $_temp0.';
  }

  @override
  String importSuccessWithDuplicates(int added, int duplicates) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added new transactions',
      one: '1 new transaction',
    );
    return 'Imported $_temp0; $duplicates already imported.';
  }

  @override
  String importNothingNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions were',
      one: '1 transaction was',
    );
    return 'Nothing new — all $_temp0 already imported.';
  }

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get cashOperation => 'Cash operation';

  @override
  String get searchHint => 'Search description or merchant';

  @override
  String get scopeThisMonth => 'This month';

  @override
  String get scopeAllTime => 'All time';

  @override
  String get allCategories => 'All categories';

  @override
  String transactionsSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0 · $total';
  }

  @override
  String get columnDate => 'Date';

  @override
  String get columnDescription => 'Description';

  @override
  String get columnCategory => 'Category';

  @override
  String get columnAmount => 'Amount';

  @override
  String get transactionsEmpty => 'No transactions match.';

  @override
  String get transactionsEmptyNoData =>
      'Nothing here yet — import a statement to get started.';

  @override
  String get deleteTransactionTooltip => 'Delete cash operation';

  @override
  String get deleteTransactionTitle => 'Delete cash operation?';

  @override
  String deleteTransactionMessage(String description) {
    return '\"$description\" will be removed.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get pinnedHint => 'Set by hand for this transaction';

  @override
  String get assignDialogTitle => 'Assign category';

  @override
  String get assignCategoryLabel => 'Category';

  @override
  String get assignApplyToLabel => 'Apply to';

  @override
  String get assignApply => 'Apply';

  @override
  String get assignReset => 'Reset to automatic';

  @override
  String get newCategory => 'New category';

  @override
  String get scopeSingle => 'Just this transaction';

  @override
  String scopeExactName(String name) {
    return 'All transactions from \"$name\"';
  }

  @override
  String get scopePattern => 'All transactions matching a pattern';

  @override
  String matchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get patternHint => 'e.g. consum, order*restaurant, /^recibo/';

  @override
  String get patternInvalid => 'Not a valid pattern.';

  @override
  String get patternSyntaxHelp =>
      'Plain text matches anywhere in the description, ignoring case and accents. Use * for any text and ? for one character, or wrap a regular expression in /slashes/.';

  @override
  String get create => 'Create';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get cashDialogTitle => 'Cash operation';

  @override
  String get cashInsert => 'Insert cash';

  @override
  String get cashWithdraw => 'Withdraw cash';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountInvalid => 'Enter an amount greater than zero.';

  @override
  String get dateLabel => 'Date';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get noteHint => 'What was it for?';

  @override
  String get save => 'Save';

  @override
  String get cashDialogHint =>
      'Cash operations are filed under Cash and are not counted as income or spending. To record something you paid for in cash, withdraw that amount, then re-file it under what it was spent on.';

  @override
  String get cashInsertedDescription => 'Cash inserted';

  @override
  String get cashWithdrawnDescription => 'Cash withdrawn';

  @override
  String get categoriesTitle => 'Categories & rules';

  @override
  String get rulesExplainer =>
      'Transactions are filed by the most specific match: a category you set for one transaction, then an exact-name rule, then a pattern rule (newest first), then the built-in keywords. Create rules by tapping a transaction and choosing what to apply it to.';

  @override
  String get notCounted => 'Not counted';

  @override
  String get incomeBadge => 'Income';

  @override
  String get cashCategoryHint =>
      'Cash movements are transfers, so they are kept out of income and expenses.';

  @override
  String get deleteCategoryTooltip => 'Delete category';

  @override
  String get deleteCategoryTitle => 'Delete category?';

  @override
  String deleteCategoryMessage(String name) {
    return '\"$name\" and the rules and assignments that use it will be removed; its transactions go back to automatic categorization.';
  }

  @override
  String get columnRuleType => 'Type';

  @override
  String get columnRuleMatch => 'Matches';

  @override
  String get columnMatches => 'Found';

  @override
  String get ruleExactName => 'Exact name';

  @override
  String get rulePattern => 'Pattern';

  @override
  String get rulesEmpty =>
      'No rules yet. Tap a transaction and apply its category to a merchant or a pattern to create one.';

  @override
  String get deleteRuleTooltip => 'Delete rule';

  @override
  String get errorUnexpected => 'Something went wrong.';

  @override
  String get errorLoadData => 'Couldn\'t load your saved data.';

  @override
  String get errorImportFormat =>
      'That file doesn\'t look like a Santander account activity export.';

  @override
  String get errorImportStatement => 'Couldn\'t import that file.';

  @override
  String get errorAddCash => 'Couldn\'t save the cash operation.';

  @override
  String get errorDeleteTransaction => 'Couldn\'t delete the transaction.';

  @override
  String get errorAssignCategory => 'Couldn\'t save the category.';

  @override
  String get errorInvalidPattern => 'That pattern isn\'t valid.';

  @override
  String get errorSaveRule => 'Couldn\'t update the rules.';

  @override
  String get errorSaveCategory => 'Couldn\'t save the category.';

  @override
  String errorCategoryExists(String name) {
    return 'A category named \"$name\" already exists.';
  }

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsLogsTitle => 'Error Logs';

  @override
  String get settingsLogsDescription =>
      'Keeps a record of any problems this app runs into, saved to a file on your device. Handy to share if you ever need to report a bug. Nothing is ever sent anywhere on its own, and you can turn this off at any time.';

  @override
  String get settingsOpenLogsFolderButton => 'Open Logs Folder';
}
