import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../pfm.dart';

/// Records a cash operation by hand: cash put into the account
/// ("insert") or taken out of it ("withdraw"). Both are filed under Cash
/// and kept out of income/expenses; re-file one on the Transactions screen
/// to record what a cash payment was actually for.
Future<void> showCashOperationDialog(
  BuildContext context, {
  required FinanceState finance,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CashOperationDialog(finance: finance),
  );
}

class _CashOperationDialog extends StatefulWidget {
  const _CashOperationDialog({required this.finance});

  final FinanceState finance;

  @override
  State<_CashOperationDialog> createState() => _CashOperationDialogState();
}

class _CashOperationDialogState extends State<_CashOperationDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  var _insert = true;
  var _date = DateTime.now();
  var _showError = false;
  var _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _cents {
    final parsed = SantanderStatementParser.parseAmountCents(_amount.text);
    return parsed == null || parsed == 0 ? null : parsed.abs();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final cents = _cents;
    if (cents == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.finance.addCashOperation(
      date: _date,
      amountCents: _insert ? cents : -cents,
      note: _note.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);

    return DialogShell(
      title: l10n.cashDialogTitle,
      width: 420,
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: AppSizes.iconMedium),
          label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
        ),
        PrimaryButton(
          onPressed: _save,
          loading: _busy,
          icon: const Icon(Icons.check, size: AppSizes.iconMedium),
          label: Text(l10n.save),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppSegmentedButton<bool>(
              selected: _insert,
              onChanged: (value) => setState(() => _insert = value),
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.add, size: AppSizes.iconMedium),
                  label: Text(l10n.cashInsert),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.remove, size: AppSizes.iconMedium),
                  label: Text(l10n.cashWithdraw),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          LabeledField(
            label: l10n.amountLabel,
            child: AppTextField(
              controller: _amount,
              hintText: '0,00',
              autofocus: true,
              onChanged: (_) {
                if (_showError) setState(() {});
              },
              onSubmitted: (_) => _save(),
            ),
          ),
          if (_showError && _cents == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.spacing4),
              child: Text(
                l10n.amountInvalid,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSizes.spacing12),
          LabeledField(
            label: l10n.dateLabel,
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: AppSizes.iconSmall),
              label: Text(DateFormat.yMMMd().format(_date)),
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          LabeledField(
            label: l10n.noteLabel,
            child: AppTextField(
              controller: _note,
              hintText: l10n.noteHint,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            l10n.cashDialogHint,
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
