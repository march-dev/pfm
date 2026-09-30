import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../pfm.dart';

/// `< September 2026 >` — steps through months, and the label opens a menu
/// to jump straight to any month that has data.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.months,
    required this.onSelected,
    required this.onPrevious,
    required this.onNext,
  });

  final YearMonth month;

  /// Months that have data, newest first.
  final List<YearMonth> months;
  final ValueChanged<YearMonth> onSelected;

  /// Null disables the corresponding arrow (already at the oldest/newest).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  static String label(YearMonth month) =>
      DateFormat.yMMMM().format(month.firstDay);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleIconButton(
          icon: const Icon(Icons.chevron_left, size: AppSizes.iconXLarge),
          onPressed: onPrevious,
          backgroundColor: Colors.transparent,
          color: colorScheme.onSurface,
          size: 32,
        ),
        PopupMenuButton<YearMonth>(
          enabled: months.isNotEmpty,
          tooltip: '',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final m in months)
              PopupMenuItem(
                value: m,
                child: Text(
                  label(m),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 132),
            child: Text(
              label(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        CircleIconButton(
          icon: const Icon(Icons.chevron_right, size: AppSizes.iconXLarge),
          onPressed: onNext,
          backgroundColor: Colors.transparent,
          color: colorScheme.onSurface,
          size: 32,
        ),
      ],
    );
  }
}
