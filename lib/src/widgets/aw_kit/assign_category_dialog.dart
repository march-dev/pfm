import 'package:flutter/material.dart';

import '../../../pfm.dart';

/// Lets the user file a transaction under a category, and choose how far
/// that reaches: just this one, every transaction from the same merchant
/// (exact name), or everything matching a pattern they write.
///
/// [finance] is passed in rather than read from the widget tree: dialogs
/// are pushed onto the root Navigator, which sits above the app's Providers.
Future<void> showAssignCategoryDialog(
  BuildContext context, {
  required FinanceState finance,
  required TransactionModel transaction,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AssignCategoryDialog(
      finance: finance,
      transaction: transaction,
    ),
  );
}

class _AssignCategoryDialog extends StatefulWidget {
  const _AssignCategoryDialog({
    required this.finance,
    required this.transaction,
  });

  final FinanceState finance;
  final TransactionModel transaction;

  @override
  State<_AssignCategoryDialog> createState() => _AssignCategoryDialogState();
}

class _AssignCategoryDialogState extends State<_AssignCategoryDialog> {
  FinanceState get _finance => widget.finance;
  TransactionModel get _tx => widget.transaction;

  late final String _merchant =
      const MerchantNormalizer().merchantOf(_tx.description);
  late final _pattern = TextEditingController(text: _merchant);
  late String _categoryId = _finance.categoryFor(_tx).id;
  var _scope = AssignmentScope.single;
  var _busy = false;

  @override
  void dispose() {
    _pattern.dispose();
    super.dispose();
  }

  bool get _patternValid => PatternMatcher.parse(_pattern.text).isValid;

  bool get _canApply =>
      !_busy && (_scope != AssignmentScope.pattern || _patternValid);

  Future<void> _apply() async {
    setState(() => _busy = true);
    final ok = await _finance.assign(
      tx: _tx,
      categoryId: _categoryId,
      scope: _scope,
      value: _scope == AssignmentScope.pattern ? _pattern.text : _merchant,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    await _finance.clearAssignment(_tx);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _createCategory() async {
    final created = await showNewCategoryDialog(context, finance: _finance);
    if (created != null && mounted) setState(() => _categoryId = created.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final hasAssignment = _finance.assignments.containsKey(_tx.id);

    return DialogShell(
      title: l10n.assignDialogTitle,
      width: 560,
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: AppSizes.iconMedium),
          label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
        ),
        if (hasAssignment)
          PrimaryButton(
            onPressed: _busy ? null : _reset,
            icon: const Icon(Icons.restart_alt, size: AppSizes.iconMedium),
            label: Text(l10n.assignReset),
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        PrimaryButton(
          onPressed: _apply,
          disabled: !_canApply,
          loading: _busy,
          icon: const Icon(Icons.check, size: AppSizes.iconMedium),
          label: Text(l10n.assignApply),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatCents(_tx.amountCents, showSign: true)}  ·  ${_tx.description}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: muted),
          ),
          const SizedBox(height: AppSizes.spacing16),
          LabeledField(
            label: l10n.assignCategoryLabel,
            child: Wrap(
              spacing: AppSizes.spacing6,
              runSpacing: AppSizes.spacing6,
              children: [
                for (final category in _finance.categories)
                  CategoryChip(
                    category: category,
                    selected: category.id == _categoryId,
                    onTap: () => setState(() => _categoryId = category.id),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: AppSizes.iconSmall),
                  label: Text(l10n.newCategory),
                  onPressed: _createCategory,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          LabeledField(
            label: l10n.assignApplyToLabel,
            child: Column(
              children: [
                _ScopeOption(
                  selected: _scope == AssignmentScope.single,
                  title: l10n.scopeSingle,
                  onTap: () => setState(() => _scope = AssignmentScope.single),
                ),
                _ScopeOption(
                  selected: _scope == AssignmentScope.exactName,
                  title: l10n.scopeExactName(_merchant),
                  subtitle: l10n.matchCount(
                    _finance.matching(RuleKind.exactName, _merchant).length,
                  ),
                  onTap: () =>
                      setState(() => _scope = AssignmentScope.exactName),
                ),
                _ScopeOption(
                  selected: _scope == AssignmentScope.pattern,
                  title: l10n.scopePattern,
                  onTap: () => setState(() => _scope = AssignmentScope.pattern),
                  details: _scope == AssignmentScope.pattern
                      ? _PatternField(
                          controller: _pattern,
                          finance: _finance,
                          onChanged: () => setState(() {}),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.details,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing6),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: AppSizes.iconMedium,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSizes.spacing10),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
              ],
            ),
          ),
        ),
        if (details != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.iconMedium + AppSizes.spacing10,
              bottom: AppSizes.spacing6,
            ),
            child: details,
          ),
      ],
    );
  }
}

class _PatternField extends StatelessWidget {
  const _PatternField({
    required this.controller,
    required this.finance,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FinanceState finance;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final valid = PatternMatcher.parse(controller.text).isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: controller,
          hintText: l10n.patternHint,
          autofocus: true,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSizes.spacing6),
        Text(
          valid
              ? l10n.matchCount(
                  finance.matching(RuleKind.pattern, controller.text).length,
                )
              : l10n.patternInvalid,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: valid ? muted : colorScheme.error,
              ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Text(
          l10n.patternSyntaxHelp,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: muted),
        ),
      ],
    );
  }
}
