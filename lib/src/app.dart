import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pfm.dart';

class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final DependencyResolver dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Lets SnackbarManager (and anything else with no BuildContext of its
      // own, e.g. a use case reporting a failure) reach the root Overlay
      // without needing one passed in.
      navigatorKey: SnackbarManager.navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
      home: _RootScaffold(dependencies: dependencies),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold({required this.dependencies});

  final DependencyResolver dependencies;

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  var _selectedIndex = 0;

  // Every screen stays mounted for the whole session (AnimatedIndexedStack
  // below), so switching tabs never tears down a screen's scroll position
  // or filters.
  static const _screens = <Widget>[
    OverviewScreen(),
    TransactionsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deps = widget.dependencies;

    final entries = [
      (Icons.insights_outlined, Icons.insights, l10n.navOverview),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navTransactions),
      (Icons.label_outline, Icons.label, l10n.navCategories),
    ];

    return MultiProvider(
      providers: [
        // The stores that need an AppLocalizations (their use cases show
        // localized failure snackbars) are built here rather than in
        // main.dart, since this is the first point a BuildContext exists.
        Provider<FinanceState>(
          create: (_) => FinanceState(
            TransactionsUseCases(deps.transactionsRepo, l10n),
            CategorizationUseCases(
              deps.rulesRepo,
              deps.assignmentsRepo,
              deps.customCategoriesRepo,
              l10n,
            ),
            StatementImportUseCases(
              deps.statementPickerRepo,
              deps.statementParser,
              deps.transactionsRepo,
              l10n,
            ),
          ),
        ),
        Provider<PeriodState>(
          create: (context) => PeriodState(context.read<FinanceState>()),
        ),
        Provider<OverviewState>(
          create: (context) => OverviewState(
            context.read<FinanceState>(),
            context.read<PeriodState>(),
          ),
        ),
        Provider<TransactionsState>(
          create: (context) => TransactionsState(
            context.read<FinanceState>(),
            context.read<PeriodState>(),
          ),
        ),
      ],
      child: Scaffold(
        body: Row(
          children: [
            RailContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                        child: RailItem(
                          icon: entries[i].$1,
                          selectedIcon: entries[i].$2,
                          label: entries[i].$3,
                          selected: _selectedIndex == i,
                          onTap: () => setState(() => _selectedIndex = i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedIndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
