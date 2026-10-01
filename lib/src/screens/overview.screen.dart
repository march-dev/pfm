import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../pfm.dart';

/// Per-month statistics: income, spending, what's left, a breakdown of
/// spending by category, and a month-by-month history.
class OverviewScreen extends StatelessObserverWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final overview = context.read<OverviewState>();

    return AppScaffold(
      body: Column(
        children: [
          const _OverviewHeader(),
          Expanded(
            child: overview.hasData
                ? const _OverviewBody()
                : const _NoDataYet(),
          ),
        ],
      ),
    );
  }
}

class _OverviewHeader extends StatelessObserverWidget {
  const _OverviewHeader();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final period = context.read<PeriodState>();
    final overview = context.read<OverviewState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final stats = overview.stats;
    final net = stats.netCents;

    return HeaderCard(
      title: l10n.overviewTitle,
      actions: [
        MonthSelector(
          month: period.month,
          months: finance.months,
          onSelected: period.select,
          onPrevious: period.canGoPrevious ? period.previous : null,
          onNext: period.canGoNext ? period.next : null,
        ),
        const SizedBox(width: AppSizes.spacing12),
        ImportStatementButton(finance: finance),
      ],
      child: Wrap(
        spacing: AppSizes.spacing24 + AppSizes.spacing12,
        runSpacing: AppSizes.spacing12,
        children: [
          StatText(
            label: l10n.statIncome,
            value: formatCents(stats.incomeCents),
            valueColor: AppColors.income,
          ),
          StatText(
            label: l10n.statExpenses,
            value: formatCents(stats.expenseCents),
            valueColor: AppColors.expense,
          ),
          StatText(
            label: l10n.statNet,
            value: formatCents(net, showSign: true),
            valueColor: net >= 0 ? AppColors.income : AppColors.expense,
          ),
          StatText(
            label: l10n.statCashOut,
            value: formatCents(stats.cashOutCents),
            valueColor: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          StatText(
            label: l10n.statCashIn,
            value: formatCents(stats.cashInCents),
            valueColor: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _NoDataYet extends StatelessWidget {
  const _NoDataYet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyPlaceholder(
            centered: true,
            icon: Icons.upload_file_outlined,
            title: l10n.overviewEmptyTitle,
            message: l10n.overviewEmptyMessage,
          ),
          const SizedBox(height: AppSizes.spacing16),
          ImportStatementButton(finance: context.read<FinanceState>()),
        ],
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody();

  @override
  Widget build(BuildContext context) {
    // The table brings its own 16px side margins (see TableCard), so the
    // category card only needs its left one for the two to sit 16px apart.
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _CategoryCard()),
        Expanded(flex: 4, child: _HistoryTable()),
      ],
    );
  }
}

class _CategoryCard extends StatelessObserverWidget {
  const _CategoryCard();

  @override
  Widget build(BuildContext context) {
    final overview = context.read<OverviewState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final stats = overview.stats;
    final breakdown = overview.expenseBreakdown;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        0,
        0,
        AppSizes.spacing16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.spendingByCategory,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.spacing12),
          if (breakdown.isEmpty)
            EmptyPlaceholder(
              icon: Icons.savings_outlined,
              title: l10n.nothingSpentTitle,
              message: l10n.nothingSpentMessage,
            )
          else ...[
            CompositionBar<CategoryModel>(
              counts: {for (final e in breakdown) e.key: e.value},
              colorOf: (c) => c.color,
              labelOf: (c) => categoryLabel(l10n, c),
              valueLabelOf: formatCents,
              maxLegendEntries: breakdown.length,
              showLegend: false,
              emptyIcon: Icons.savings_outlined,
              emptyTitle: l10n.nothingSpentTitle,
              emptyMessage: l10n.nothingSpentMessage,
            ),
            const SizedBox(height: AppSizes.spacing8),
            Expanded(
              child: SingleChildScrollView(
                child: CategoryBreakdown(
                  entries: breakdown,
                  totalCents: stats.expenseCents,
                ),
              ),
            ),
          ],
          if (stats.cashOutCents > 0 || stats.cashInCents > 0) ...[
            const HairlineDivider(),
            const SizedBox(height: AppSizes.spacing8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: AppSizes.iconSmall,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    l10n.cashNote(
                      formatCents(stats.cashOutCents),
                      formatCents(stats.cashInCents),
                    ),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

const _historyColumns = [
  FlexColumn(flex: 3),
  DividerColumn(),
  FlexColumn(flex: 3),
  DividerColumn(),
  FlexColumn(flex: 3),
  DividerColumn(),
  FlexColumn(flex: 3),
];

class _HistoryTable extends StatelessObserverWidget {
  const _HistoryTable();

  @override
  Widget build(BuildContext context) {
    final overview = context.read<OverviewState>();
    final period = context.read<PeriodState>();
    final l10n = AppLocalizations.of(context)!;

    const rightPad = EdgeInsets.only(right: AppSizes.spacing12);
    const leftPad = EdgeInsets.only(left: AppSizes.spacing16);

    Widget money(int cents, {Color? color, bool bold = false}) => Padding(
          padding: rightPad,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatCents(cents),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: color,
                    fontWeight: bold ? FontWeight.w600 : null,
                  ),
            ),
          ),
        );

    return AppTable<MonthlyStats, Never>(
      columns: _historyColumns,
      items: overview.history,
      rowKey: (stats) => ValueKey(stats.month.key),
      emptyMessage: l10n.historyEmpty,
      onRowTap: (stats) => period.select(stats.month),
      headerBuilder: (context) => [
        HeaderText(l10n.columnMonth, padding: leftPad),
        HeaderText(l10n.statIncome, alignment: Alignment.centerRight, padding: rightPad),
        HeaderText(l10n.statExpenses, alignment: Alignment.centerRight, padding: rightPad),
        HeaderText(l10n.statNet, alignment: Alignment.centerRight, padding: rightPad),
      ],
      rowBuilder: (context, stats, isHovered) => [
        Observer(
          builder: (context) {
            final selected = period.month == stats.month;
            return Padding(
              padding: leftPad,
              child: Text(
                MonthSelector.label(stats.month),
                overflow: TextOverflow.ellipsis,
                style: selected
                    ? Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        )
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            );
          },
        ),
        money(stats.incomeCents, color: AppColors.income),
        money(stats.expenseCents, color: AppColors.expense),
        money(
          stats.netCents,
          color: stats.netCents >= 0 ? AppColors.income : AppColors.expense,
          bold: true,
        ),
      ],
    );
  }
}
