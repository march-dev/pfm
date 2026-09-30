import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../pfm.dart';

/// "Import statement" — picks a Santander .xlsx, imports it, and reports
/// what happened in a snackbar.
class ImportStatementButton extends StatelessWidget {
  const ImportStatementButton({super.key, required this.finance});

  final FinanceState finance;

  Future<void> _import(AppLocalizations l10n) async {
    final outcome = await finance.importStatement();
    if (outcome == null) return;

    SnackbarManager.show(
      outcome.added == 0
          ? l10n.importNothingNew(outcome.duplicates)
          : outcome.duplicates == 0
              ? l10n.importSuccess(outcome.added)
              : l10n.importSuccessWithDuplicates(
                  outcome.added,
                  outcome.duplicates,
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Observer(
      builder: (_) => PrimaryButton(
        onPressed: () => _import(l10n),
        loading: finance.importing,
        icon: const Icon(Icons.upload_file_outlined, size: AppSizes.iconMedium),
        label: Text(l10n.importStatement),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}
