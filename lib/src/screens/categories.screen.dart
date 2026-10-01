import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../pfm.dart';

/// The categories the app files things under, and the rules the user has
/// taught it.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: Column(
        children: [
          _CategoriesHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 340, child: _CategoryList()),
                Expanded(child: _RulesTable()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  const _CategoriesHeader();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return HeaderCard(
      title: l10n.categoriesTitle,
      actions: [
        PrimaryButton(
          onPressed: () => showNewCategoryDialog(context, finance: finance),
          icon: const Icon(Icons.add, size: AppSizes.iconMedium),
          label: Text(l10n.newCategory),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ],
      child: Text(
        l10n.rulesExplainer,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

class _CategoryList extends StatelessObserverWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        0,
        0,
        AppSizes.spacing16,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: ListView(
        children: [
          for (final category in finance.categories)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing16,
                vertical: AppSizes.spacing6,
              ),
              child: Row(
                children: [
                  Icon(categoryIcon(category),
                      size: AppSizes.iconMedium, color: category.color),
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Text(
                      categoryLabel(l10n, category),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (category.kind == CategoryKind.transfer)
                    Tooltip(
                      message: l10n.cashCategoryHint,
                      child: PillBadge(
                        child: Text(
                          l10n.notCounted,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: muted),
                        ),
                      ),
                    ),
                  if (category.kind == CategoryKind.income)
                    PillBadge(
                      child: Text(
                        l10n.incomeBadge,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: muted),
                      ),
                    ),
                  if (!category.builtIn)
                    CircleIconButton(
                      size: 28,
                      backgroundColor: Colors.transparent,
                      color: muted,
                      tooltip: l10n.deleteCategoryTooltip,
                      icon: const Icon(Icons.delete_outline,
                          size: AppSizes.iconMedium),
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: l10n.deleteCategoryTitle,
                          message:
                              l10n.deleteCategoryMessage(category.name ?? ''),
                          confirmLabel: l10n.delete,
                        );
                        if (confirmed) await finance.deleteCategory(category);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const _ruleColumns = [
  FixedColumn(108),
  DividerColumn(),
  FlexColumn(flex: 3),
  DividerColumn(),
  FixedColumn(200),
  DividerColumn(),
  FixedColumn(84),
  DividerColumn(),
  FixedColumn(AppSizes.actionColumnSize + AppSizes.spacing12 * 2),
];

class _RulesTable extends StatelessObserverWidget {
  const _RulesTable();

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final rules = [...finance.rules]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AppTable<CategoryRule, Never>(
      columns: _ruleColumns,
      items: rules,
      rowKey: (rule) => ValueKey(rule.id),
      emptyMessage: l10n.rulesEmpty,
      headerBuilder: (context) => [
        HeaderText(l10n.columnRuleType,
            padding: const EdgeInsets.only(left: AppSizes.spacing16)),
        HeaderText(l10n.columnRuleMatch,
            padding: const EdgeInsets.only(left: AppSizes.spacing12)),
        HeaderText(l10n.columnCategory,
            padding: const EdgeInsets.only(left: AppSizes.spacing12)),
        HeaderText(
          l10n.columnMatches,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSizes.spacing12),
        ),
        const HeaderEmpty(),
      ],
      rowBuilder: (context, rule, isHovered) => [
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.spacing16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PillBadge(
              child: Text(
                rule.kind == RuleKind.exactName
                    ? l10n.ruleExactName
                    : l10n.rulePattern,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              rule.value,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.spacing12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Observer(
              builder: (context) {
                final category = finance.categoryById[rule.categoryId];
                return category == null
                    ? const SizedBox.shrink()
                    : CategoryChip(category: category);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.spacing12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Observer(
              builder: (context) => Text(
                '${finance.matching(rule.kind, rule.value).length}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: muted),
              ),
            ),
          ),
        ),
        Center(
          child: CircleIconButton(
            size: AppSizes.actionColumnSize,
            backgroundColor: Colors.transparent,
            color: muted,
            tooltip: l10n.deleteRuleTooltip,
            icon: const Icon(Icons.delete_outline, size: AppSizes.iconLarge),
            onPressed: () => finance.deleteRule(rule),
          ),
        ),
      ],
    );
  }
}
