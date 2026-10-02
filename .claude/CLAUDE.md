# PFM — project memory

Personal finance manager for a Santander (Spain) account. Imports the
"account activity" `.xlsx` from the Santander app, builds per-month income /
spending stats, categorizes transactions (automatically + user rules), handles
manual cash operations. macOS desktop app (sandboxed), dark theme, English-only
UI. README.md covers the user-facing feature list; this file is what you need to
*work* on it.

Architecture and UIKit were taken from `~/Projects/other/repo_manager` ("Depot").
Treat that repo as the style reference; this app's copy of its UIKit has since
been modified (see "UIKit changes" below), so don't blindly re-copy.

## Commands

Always use `fvm` (Flutter 3.38.9 pinned in `.fvmrc`).

```sh
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # MobX *.g.dart (committed)
fvm flutter gen-l10n                                           # after editing lib/l10n/app_en.arb
fvm flutter analyze                                            # keep at "No issues found"
fvm flutter test --reporter compact                            # ~15s, 60+ tests
fvm flutter build macos --debug                                # -> build/macos/.../PFM.app
```

Use `--reporter compact` (or `failures-only`): the default reporter floods output.
Run long things with `run_in_background`; a hung test run must be killed with
`pkill -f flutter_tester`. There is no `timeout` binary on this machine.

## Layout (`lib/src`, each folder has a barrel `x.dart` beside it)

`models → services → repos → domain (use cases) → state (MobX) → screens / widgets`,
wired by `dependency_resolver.dart` (composition root), `app.dart` (Providers + rail),
`lib/pfm.dart` (root barrel). `widgets/ui_kit` = domain-free kit; `widgets/aw_kit` = app-aware.

- **services/** pure logic, no Flutter state: `XlsxReader` (zip+xml by hand, no excel
  package), `SantanderStatementParser`, `MerchantNormalizer`, `PatternMatcher`,
  `RuleMatcher`, `BuiltInCategoryRules`, `TransactionCategorizer`,
  `StatisticsCalculator`, `FinanceCodec` (JSON in Hive).
- **repos/** Hive boxes `settings` (rules, assignments, custom categories) and
  `transactions` (one JSON entry per tx) + `StatementPickerRepo` (file_picker).
- **domain/** use cases own persistence + validation + error snackbars (need an
  `AppLocalizations`, so they are built in `_RootScaffoldState.build`, not main).
- **state/** `FinanceState` (source of truth), `PeriodState` (selected month),
  `OverviewState`, `TransactionsState` (filters + sort). Stores are plain `Provider`s.
- Screens: Overview, Transactions, Categories & rules, Settings (pinned at the bottom of
  the rail under a divider; one card for now: **Error Logs**).
- **Error handling convention** (same as repo_manager): a use case catches, then
  `logError(...)` + `SnackbarManager.show(l10n.errorX)` (orange = problem) and returns
  null/false/[] so callers never see an exception. Successes use `showSuccess` (green).
  Validation that needs no I/O runs *before* storage so its specific message wins.
  Preference saves (`AppSettingsUseCases`) log only, no snackbar. Anything uncaught is
  caught by `installGlobalErrorHandlers()` (identical to repo_manager's) -> log + generic
  "Something went wrong." snackbar. `test/error_handling_test.dart` covers all of this.
- **Error logging** (ported from repo_manager): `logError(action, error, stack)` always
  `debugPrint`s and, if enabled, appends to this launch's `session_<time>.log` under
  `<support dir>/logs` (10MB total cap, oldest sessions pruned at launch, per-file cap).
  State is module-level in `utils/error_logging.util.dart` on purpose — callers have no DI.
  `ErrorLogRepo.init` never throws (a failure = no file logging). Preference
  (`AppSettingsRepo`, on by default) + live toggle (`ErrorLogUseCases`); "Open Logs Folder"
  goes through `FileManagerRepo` (`open`, verified to work inside the sandbox).

## Domain rules (decisions already made — don't relitigate without asking)

- Money is **integer cents** everywhere. Months bucket by the statement's
  **Transaction date** (reconciles with the bank's running balance), not value date.
- Tx id = sha1 of date|valueDate|description|amount|balance(+#n). Balance in the key
  is what makes identical purchases distinct and re-imports idempotent.
- Category priority, most specific wins: one-off assignment > exact-name rule
  (merchant via `MerchantNormalizer`) > pattern rule (newest first) > manual cash op
  → Cash > built-in keyword dictionary > fallback (money in → Income, out → Other).
  Creating a rule deletes earlier one-off assignments it covers.
- Patterns: plain = contains; `*`/`?` wildcards; `/regex/`. Accent/case-insensitive.
- **Cash is `CategoryKind.transfer`**: ATM withdrawals and manual insert/withdraw go
  to Cash and are excluded from income/expenses (else spending is double counted).
  A cash purchase = withdraw, then re-file under the real category.
- Health and Beauty are separate categories. Custom categories are expense-kind only.
  Rent has no category of its own (lands in Other unless the user adds one).
- Built-in keywords match whole words (`bar` ≠ `barcelona`); `x*` = prefix.
  The keyword `internet` was removed because "COMPRA INTERNET EN …" matched it.

## UI conventions / gotchas

- Row-control height is `AppSizes.controlHeight = 32` for text field, button,
  segmented button, split button, dropdown, month selector. **macOS defaults to
  `VisualDensity.compact`, which shrinks Material controls by 8px**, so
  `PrimaryButton` and `AppTextField` pin `VisualDensity.standard` and the segmented
  button uses compact on purpose (its height is 40 + density). Any new control must be
  checked under the macOS platform override (see `test/control_height_test.dart`).
- An outlined `TextField` paints its border around text + `contentPadding`;
  `InputDecoration.constraints` alone does NOT make the outline 32px tall.
  `AppTextField` computes vertical padding from the real line height.
- `AppTable` rows are built lazily and **outside** the surrounding Observer: wrap any
  cell that reads MobX state in its own `Observer`. Rows off-screen don't exist
  (tests must search/filter first). Dividers: header only (kit design); never in rows.
- Dialogs sit on the root Navigator, **above the Providers**: pass `FinanceState`
  explicitly (`showAssignCategoryDialog(context, finance: …)`).
- `CupertinoIcons` need the `cupertino_icons` dependency (missing = "?" boxes).
- Dropdowns/menus use `MenuAnchor` with `compactMenuStyle` / `compactMenuButtonStyle`
  (the split-button style). `AppDropdown` keeps its arrow pinned right.

### UIKit changes vs repo_manager
`AppSizes.controlHeight`; `AppTextField` (height/density); `PrimaryButton` and
`AppSegmentedButton` (height); `SplitButton` default height; `CompositionBar.showLegend`;
new `AppDropdown`; new `HeaderFilterButton` (lives in `table/app_table.dart` to reuse the
private ink shell; whole header cell is tappable, bright `onSurface` when active);
theme comments/colors scrubbed of repo_manager references (`AppColors.income/expense/
categoryPalette` added).

## Testing notes

- Real Hive on a temp dir inside widget tests: Hive I/O is real, tests are fake-async.
  Tap handlers that **save** must be dispatched via `tester.runAsync` (`tapAndSave`),
  then pump in a loop with short real waits (`settleIo`); `Hive.close()` in teardown
  hangs if a write is stranded. Reset `debugDefaultTargetPlatformOverride` in a
  `finally`, not `addTearDown`.
- Mock `plugins.flutter.io/path_provider` to point `DependencyResolver.create()` at a temp dir.
- Tests read `test/data/TransactionExcelFile.xlsx` (real export; 40 rows, Sept 2026).
- Widget boxes can lie: to verify what is *painted*, render via `RepaintBoundary.toImage`
  and read pixels / view the PNG (test fonts are Ahem blocks, shapes are real).
- Screenshots of the running app are not possible from here (`screencapture` denied).
  Launching works: `open build/macos/Build/Products/Debug/PFM.app`. To see `debugPrint`
  output of the real sandboxed app use `fvm flutter run -d macos` — running the binary
  directly sends it to the system log, not stdout (looks like a hang; it isn't).
- Widget tests can't override `debugPrint` (Flutter's invariant check); plain `test()` can.

## Environment

- Bundle id `march.dev.pfm`; macOS sandbox with `files.user-selected.read-only`
  (file picker) — data lives in the sandbox container, expected at
  `~/Library/Containers/march.dev.pfm/Data/Library/Application Support/march.dev.pfm/`
  (`settings.hive`, `transactions.hive`, `logs/`; confirmed under `march.dev.pfm`; the old
  empty `march.dev.flutterProjectTemplate` container can't be deleted by us, macOS blocks it).
- `pubspec.yaml` pins `dependency_overrides: path_provider_foundation: 2.4.4` (newer
  versions crash at launch on this machine via objective_c native assets).
- `test/data/TransactionExcelFile.xlsx` contains the holder's name, IBAN and card
  fragments and is in git history; remote is github.com/march-dev/pfm — don't
  suggest pushing/publishing it, and don't copy its personal data elsewhere.
- Android/iOS/Linux/Windows runners exist from the template but are untested.

## Working with this user

- Short, precise UI tweak requests; they look at the real macOS app and report pixels
  ("24px instead of 32"). Prefer measurable verification (tests that fail first)
  over assuming. Say plainly when something could not be checked visually.
- They commit themselves; don't commit/push unless asked.
- When they say "move X to Y" in a header/table, change layout only; keep behaviour.

## Not built (ideas)
Multi-account support, export, cross-month charts, editing the built-in keyword
dictionary from the UI, localization beyond English, light theme.
