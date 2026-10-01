import 'package:flutter/cupertino.dart';
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
          size: AppSizes.controlHeight,
        ),
        MenuAnchor(
          style: compactMenuStyle(context),
          alignmentOffset: const Offset(0, AppSizes.spacing8),
          menuChildren: [
            for (final m in months)
              MenuItemButton(
                style: compactMenuButtonStyle(context),
                trailingIcon: m == month
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        size: AppSizes.iconSmall)
                    : null,
                onPressed: () => onSelected(m),
                child: Text(label(m)),
              ),
          ],
          builder: (context, controller, child) => InkWell(
            borderRadius: BorderRadius.circular(AppSizes.controlHeight / 2),
            onTap: months.isEmpty
                ? null
                : () =>
                    controller.isOpen ? controller.close() : controller.open(),
            child: Container(
              height: AppSizes.controlHeight,
              constraints: const BoxConstraints(minWidth: 132),
              alignment: Alignment.center,
              child: Text(
                label(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        ),
        CircleIconButton(
          icon: const Icon(Icons.chevron_right, size: AppSizes.iconXLarge),
          onPressed: onNext,
          backgroundColor: Colors.transparent,
          color: colorScheme.onSurface,
          size: AppSizes.controlHeight,
        ),
      ],
    );
  }
}
