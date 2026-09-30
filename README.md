# PFM

Personal finance manager for a Santander (Spain) account. Import the
"account activity" export (`.xlsx`) from the Santander app and get per-month
income and spending, split into categories you can correct and teach.

## What it does

- **Import** a Santander `.xlsx`. Re-importing an overlapping export is safe:
  every line has a stable id, so nothing is duplicated.
- **Monthly statistics**: income, expenses, net, and spending by category,
  plus a month-by-month history.
- **Categories** out of the box: cafes & restaurants, groceries, health,
  beauty, transport, utility bills, taxes, gifts, other — plus Income and
  Cash. Health and beauty are separate. You can add your own.
- **Manual assignment** (tap any transaction), with a choice of reach:
  - just that transaction,
  - every transaction from the same merchant (exact name),
  - every transaction matching a pattern you write.
- **Cash**: ATM withdrawals and hand-entered cash operations (insert /
  withdraw) live in their own *Cash* category and are **not** counted as
  income or spending — counting an ATM withdrawal as an expense would count
  the same money twice once it is spent. To record something you paid for in
  cash, withdraw that amount and re-file it under what it was spent on.

### Pattern syntax

| You write            | It matches                                              |
| -------------------- | ------------------------------------------------------- |
| `consum`             | the text anywhere in the description                    |
| `order*restaurant`   | `*` = any text, `?` = one character                     |
| `/^recibo (digi\|aqua)/` | a regular expression, wrapped in slashes           |

Matching ignores case and accents.

### How a transaction gets its category

Most specific wins:

1. a category you set for that one transaction,
2. an exact-name rule,
3. a pattern rule (newest first),
4. the built-in keyword dictionary (Spanish chains and common words),
5. otherwise: money in → Income, money out → Other.

Creating a rule replaces earlier one-off assignments it covers, so the
newest instruction always wins.

## Architecture

Follows the layering of `repo_manager`:

```
lib/
  pfm.dart                barrel
  main.dart
  l10n/                   app_en.arb -> generated AppLocalizations
  src/
    models/               plain data (Transaction, Category, Rule, ...)
    services/             pure logic: xlsx reading, statement parsing,
                          merchant/pattern matching, categorization, stats
    repos/                Hive boxes + the file picker
    domain/               use cases: persistence + validation + error snackbars
    state/                MobX stores (FinanceState is the source of truth)
    screens/              Overview, Transactions, Categories & rules
    widgets/ui_kit/       domain-free components (migrated from repo_manager)
    widgets/aw_kit/       app-aware components (dialogs, chips, ...)
    theme/                colors, sizes, typography (dark theme)
    dependency_resolver.dart   composition root
```

Amounts are integer cents everywhere (never doubles). Statistics are bucketed
by the statement's *Transaction date*, so monthly totals reconcile with the
bank's own running balance.

## Development

```sh
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # MobX .g.dart
fvm flutter gen-l10n
fvm flutter test
fvm flutter run -d macos
```

`test/data/TransactionExcelFile.xlsx` is a real export used by the tests; it
contains the account holder's name, IBAN and card fragments, so keep it out of
any public repository.
