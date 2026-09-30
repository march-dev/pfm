import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../pfm.dart';

/// Every transaction for the selected month (or the whole history), with
/// search and category filters. Tapping a row opens the assign dialog;
/// cash operations are entered from here too.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: Column(
        children: [
          _TransactionsHeader(),
          Expanded(child: _TransactionsTable()),
        ],
      ),
    );
  }
}

class _TransactionsHeader extends StatelessObserverWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final period = context.read<PeriodState>();
    final state = context.read<TransactionsState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final visible = state.visible;
    final total = visible.fold<int>(0, (sum, tx) => sum + tx.amountCents);

    return HeaderCard(
      title: l10n.transactionsTitle,
      actions: [
        if (!state.allMonths) ...[
          MonthSelector(
            month: period.month,
            months: finance.months,
            onSelected: period.select,
            onPrevious: period.canGoPrevious ? period.previous : null,
            onNext: period.canGoNext ? period.next : null,
          ),
          const SizedBox(width: AppSizes.spacing12),
        ],
        PrimaryButton(
          onPressed: () => showCashOperationDialog(context, finance: finance),
          icon: const Icon(Icons.payments_outlined, size: AppSizes.iconMedium),
          label: Text(l10n.cashOperation),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
        ),
        const SizedBox(width: AppSizes.spacing8),
        ImportStatementButton(finance: finance),
      ],
      // A Wrap (not a Row) so the filters reflow onto a second line in a
      // narrow window instead of overflowing.
      child: Wrap(
        spacing: AppSizes.spacing12,
        runSpacing: AppSizes.spacing8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SearchField(
            value: state.search,
            onChanged: state.setSearch,
            hintText: l10n.searchHint,
            width: 260,
          ),
          _CategoryFilter(state: state, finance: finance),
          AppSegmentedButton<bool>(
            selected: state.allMonths,
            onChanged: state.setAllMonths,
            segments: [
              ButtonSegment(value: false, label: Text(l10n.scopeThisMonth)),
              ButtonSegment(value: true, label: Text(l10n.scopeAllTime)),
            ],
          ),
          Text(
            l10n.transactionsSummary(
              visible.length,
              formatCents(total, showSign: true),
            ),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.state, required this.finance});

  final TransactionsState state;
  final FinanceState finance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Observer(
        builder: (context) => DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: state.categoryFilter,
            isDense: true,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            style: Theme.of(context).textTheme.bodyMedium,
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.allCategories)),
              for (final category in finance.categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      ColorDot(color: category.color, size: 8),
                      const SizedBox(width: AppSizes.spacing8),
                      Text(categoryLabel(l10n, category)),
                    ],
                  ),
                ),
            ],
            onChanged: state.setCategoryFilter,
          ),
        ),
      ),
    );
  }
}

const _columns = [
  FixedColumn(104),
  FlexColumn(flex: 4),
  FixedColumn(220),
  FixedColumn(128),
  FixedColumn(AppSizes.actionColumnSize + AppSizes.spacing12 * 2),
];

class _TransactionsTable extends StatelessObserverWidget {
  const _TransactionsTable();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final state = context.read<TransactionsState>();
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    const merchants = MerchantNormalizer();
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);

    return AppTable<TransactionModel, Never>(
      columns: _columns,
      items: state.visible,
      rowKey: (tx) => ValueKey(tx.id),
      emptyMessage: finance.transactions.isEmpty
          ? l10n.transactionsEmptyNoData
          : l10n.transactionsEmpty,
      onRowTap: (tx) => showAssignCategoryDialog(
        context,
        finance: finance,
        transaction: tx,
      ),
      headerBuilder: (context) => [
        HeaderText(l10n.columnDate, padding: const EdgeInsets.only(left: AppSizes.spacing16)),
        HeaderText(l10n.columnDescription, padding: const EdgeInsets.only(left: AppSizes.spacing12)),
        HeaderText(l10n.columnCategory),
        HeaderText(
          l10n.columnAmount,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSizes.spacing12),
        ),
        const HeaderEmpty(),
      ],
      rowBuilder: (context, tx, isHovered) {
        final merchant = merchants.merchantOf(tx.description);
        return [
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.spacing16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                dateFormat.format(tx.date),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: muted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (tx.description != merchant)
                  Text(
                    tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          // rowBuilder runs inside AppTable's lazily-built row widgets,
          // outside the Observer scope wrapping this build() — without its
          // own Observer here, re-filing a transaction wouldn't repaint
          // its chip until something else happened to rebuild the row.
          Align(
            alignment: Alignment.centerLeft,
            child: Observer(
              builder: (context) => CategoryChip(
                category: finance.categoryFor(tx),
                pinned: finance.assignments.containsKey(tx.id),
                onTap: () => showAssignCategoryDialog(
                  context,
                  finance: finance,
                  transaction: tx,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.spacing12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatCents(tx.amountCents, showSign: true, currency: tx.currency),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: tx.isIncoming ? AppColors.income : null,
                    ),
              ),
            ),
          ),
          if (tx.isManual)
            Center(
              child: CircleIconButton(
                size: AppSizes.actionColumnSize,
                backgroundColor: Colors.transparent,
                color: muted,
                tooltip: l10n.deleteTransactionTooltip,
                icon: const Icon(Icons.delete_outline, size: AppSizes.iconLarge),
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: l10n.deleteTransactionTitle,
                    message: l10n.deleteTransactionMessage(tx.description),
                    confirmLabel: l10n.delete,
                  );
                  if (confirmed) await finance.deleteTransaction(tx);
                },
              ),
            )
          else
            const SizedBox.shrink(),
        ];
      },
    );
  }
}
