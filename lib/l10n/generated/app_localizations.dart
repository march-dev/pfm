import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PFM'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @categoryCafeResto.
  ///
  /// In en, this message translates to:
  /// **'Cafes & restaurants'**
  String get categoryCafeResto;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get categoryBeauty;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utility bills'**
  String get categoryUtilities;

  /// No description provided for @categoryTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get categoryTaxes;

  /// No description provided for @categoryGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryGifts;

  /// No description provided for @categoryCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get categoryCash;

  /// No description provided for @categoryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryIncome;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @statIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get statIncome;

  /// No description provided for @statExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get statExpenses;

  /// No description provided for @statNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get statNet;

  /// No description provided for @statCashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get statCashOut;

  /// No description provided for @statCashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get statCashIn;

  /// No description provided for @overviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get overviewEmptyTitle;

  /// No description provided for @overviewEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Import an account activity export (.xlsx) from Santander to see your monthly income and spending.'**
  String get overviewEmptyMessage;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @nothingSpentTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent this month'**
  String get nothingSpentTitle;

  /// No description provided for @nothingSpentMessage.
  ///
  /// In en, this message translates to:
  /// **'No expenses were recorded in this month.'**
  String get nothingSpentMessage;

  /// No description provided for @cashNote.
  ///
  /// In en, this message translates to:
  /// **'Cash: {out} taken out, {inn} put in — moves of money, not counted as spending.'**
  String cashNote(String out, String inn);

  /// No description provided for @columnMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get columnMonth;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No months yet.'**
  String get historyEmpty;

  /// No description provided for @importStatement.
  ///
  /// In en, this message translates to:
  /// **'Import statement'**
  String get importStatement;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count, plural, =1{1 new transaction} other{{count} new transactions}}.'**
  String importSuccess(int count);

  /// No description provided for @importSuccessWithDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Imported {added, plural, =1{1 new transaction} other{{added} new transactions}}; {duplicates} already imported.'**
  String importSuccessWithDuplicates(int added, int duplicates);

  /// No description provided for @importNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new — all {count, plural, =1{1 transaction was} other{{count} transactions were}} already imported.'**
  String importNothingNew(int count);

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @cashOperation.
  ///
  /// In en, this message translates to:
  /// **'Cash operation'**
  String get cashOperation;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description or merchant'**
  String get searchHint;

  /// No description provided for @scopeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get scopeThisMonth;

  /// No description provided for @scopeAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get scopeAllTime;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @transactionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}} · {total}'**
  String transactionsSummary(int count, String total);

  /// No description provided for @columnDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get columnDate;

  /// No description provided for @columnDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get columnDescription;

  /// No description provided for @columnCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get columnCategory;

  /// No description provided for @columnAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get columnAmount;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions match.'**
  String get transactionsEmpty;

  /// No description provided for @transactionsEmptyNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet — import a statement to get started.'**
  String get transactionsEmptyNoData;

  /// No description provided for @deleteTransactionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete cash operation'**
  String get deleteTransactionTooltip;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cash operation?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{description}\" will be removed.'**
  String deleteTransactionMessage(String description);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @pinnedHint.
  ///
  /// In en, this message translates to:
  /// **'Set by hand for this transaction'**
  String get pinnedHint;

  /// No description provided for @assignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign category'**
  String get assignDialogTitle;

  /// No description provided for @assignCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get assignCategoryLabel;

  /// No description provided for @assignApplyToLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get assignApplyToLabel;

  /// No description provided for @assignApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get assignApply;

  /// No description provided for @assignReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get assignReset;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @scopeSingle.
  ///
  /// In en, this message translates to:
  /// **'Just this transaction'**
  String get scopeSingle;

  /// No description provided for @scopeExactName.
  ///
  /// In en, this message translates to:
  /// **'All transactions from \"{name}\"'**
  String scopeExactName(String name);

  /// No description provided for @scopePattern.
  ///
  /// In en, this message translates to:
  /// **'All transactions matching a pattern'**
  String get scopePattern;

  /// No description provided for @matchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 transaction} other{{count} transactions}}'**
  String matchCount(int count);

  /// No description provided for @patternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. consum, order*restaurant, /^recibo/'**
  String get patternHint;

  /// No description provided for @patternInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid pattern.'**
  String get patternInvalid;

  /// No description provided for @patternSyntaxHelp.
  ///
  /// In en, this message translates to:
  /// **'Plain text matches anywhere in the description, ignoring case and accents. Use * for any text and ? for one character, or wrap a regular expression in /slashes/.'**
  String get patternSyntaxHelp;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// No description provided for @cashDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash operation'**
  String get cashDialogTitle;

  /// No description provided for @cashInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert cash'**
  String get cashInsert;

  /// No description provided for @cashWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw cash'**
  String get cashWithdraw;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get amountInvalid;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cashDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Cash operations are filed under Cash and are not counted as income or spending. To record something you paid for in cash, withdraw that amount, then re-file it under what it was spent on.'**
  String get cashDialogHint;

  /// No description provided for @cashInsertedDescription.
  ///
  /// In en, this message translates to:
  /// **'Cash inserted'**
  String get cashInsertedDescription;

  /// No description provided for @cashWithdrawnDescription.
  ///
  /// In en, this message translates to:
  /// **'Cash withdrawn'**
  String get cashWithdrawnDescription;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories & rules'**
  String get categoriesTitle;

  /// No description provided for @rulesExplainer.
  ///
  /// In en, this message translates to:
  /// **'Transactions are filed by the most specific match: a category you set for one transaction, then an exact-name rule, then a pattern rule (newest first), then the built-in keywords. Create rules by tapping a transaction and choosing what to apply it to.'**
  String get rulesExplainer;

  /// No description provided for @notCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted'**
  String get notCounted;

  /// No description provided for @incomeBadge.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeBadge;

  /// No description provided for @cashCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Cash movements are transfers, so they are kept out of income and expenses.'**
  String get cashCategoryHint;

  /// No description provided for @deleteCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategoryTooltip;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and the rules and assignments that use it will be removed; its transactions go back to automatic categorization.'**
  String deleteCategoryMessage(String name);

  /// No description provided for @columnRuleType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get columnRuleType;

  /// No description provided for @columnRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get columnRuleMatch;

  /// No description provided for @columnMatches.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get columnMatches;

  /// No description provided for @ruleExactName.
  ///
  /// In en, this message translates to:
  /// **'Exact name'**
  String get ruleExactName;

  /// No description provided for @rulePattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get rulePattern;

  /// No description provided for @rulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Tap a transaction and apply its category to a merchant or a pattern to create one.'**
  String get rulesEmpty;

  /// No description provided for @deleteRuleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get deleteRuleTooltip;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnexpected;

  /// No description provided for @errorLoadData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved data.'**
  String get errorLoadData;

  /// No description provided for @errorImportFormat.
  ///
  /// In en, this message translates to:
  /// **'That file doesn\'t look like a Santander account activity export.'**
  String get errorImportFormat;

  /// No description provided for @errorImportStatement.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import that file.'**
  String get errorImportStatement;

  /// No description provided for @errorAddCash.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the cash operation.'**
  String get errorAddCash;

  /// No description provided for @errorDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the transaction.'**
  String get errorDeleteTransaction;

  /// No description provided for @errorAssignCategory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the category.'**
  String get errorAssignCategory;

  /// No description provided for @errorInvalidPattern.
  ///
  /// In en, this message translates to:
  /// **'That pattern isn\'t valid.'**
  String get errorInvalidPattern;

  /// No description provided for @errorSaveRule.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the rules.'**
  String get errorSaveRule;

  /// No description provided for @errorSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the category.'**
  String get errorSaveCategory;

  /// No description provided for @errorCategoryExists.
  ///
  /// In en, this message translates to:
  /// **'A category named \"{name}\" already exists.'**
  String errorCategoryExists(String name);

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Logs'**
  String get settingsLogsTitle;

  /// No description provided for @settingsLogsDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps a record of any problems this app runs into, saved to a file on your device. Handy to share if you ever need to report a bug. Nothing is ever sent anywhere on its own, and you can turn this off at any time.'**
  String get settingsLogsDescription;

  /// No description provided for @settingsOpenLogsFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Open Logs Folder'**
  String get settingsOpenLogsFolderButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
