import 'package:flutter/material.dart';

import '../../../pfm.dart';

/// Prompts for a name and color and creates a custom category. Resolves to
/// the new category, or null if cancelled or it couldn't be created.
Future<CategoryModel?> showNewCategoryDialog(
  BuildContext context, {
  required FinanceState finance,
}) {
  return showDialog<CategoryModel>(
    context: context,
    builder: (_) => _NewCategoryDialog(finance: finance),
  );
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog({required this.finance});

  final FinanceState finance;

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();
  var _color = AppColors.categoryPalette.first;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final before = widget.finance.customCategories.map((c) => c.id).toSet();
    final ok = await widget.finance.createCategory(name, _color);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      return;
    }
    Navigator.of(context).pop(
      widget.finance.customCategories.firstWhere((c) => !before.contains(c.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return DialogShell(
      title: l10n.newCategory,
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: AppSizes.iconMedium),
          label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
        ),
        PrimaryButton(
          onPressed: _create,
          loading: _busy,
          icon: const Icon(Icons.check, size: AppSizes.iconMedium),
          label: Text(l10n.create),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _name,
            hintText: l10n.categoryNameHint,
            autofocus: true,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing8,
            runSpacing: AppSizes.spacing8,
            children: [
              for (final color in AppColors.categoryPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == _color
                            ? colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
