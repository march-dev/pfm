import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../context_menu/context_menu.dart';

class AppDropdownItem<T> {
  const AppDropdownItem(
      {required this.value, required this.label, this.leading});

  final T value;
  final String label;

  /// Shown before the label, both in the menu and, once chosen, in the
  /// closed field (a color dot, an icon, ...).
  final Widget? leading;
}

/// A single-select dropdown: a field-shaped trigger (same height and pill
/// outline as [AppTextField]) that opens the same compact menu as
/// [SplitButton]'s chevron.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.minWidth = 0,
  });

  final List<AppDropdownItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Keeps the field from shrinking below this when its current label is
  /// short, so it doesn't change width every time the selection does.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final current = items.firstWhere(
      (item) => item.value == selected,
      orElse: () => items.first,
    );

    return MenuAnchor(
      style: compactMenuStyle(context),
      alignmentOffset: const Offset(0, AppSizes.spacing8),
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            style: compactMenuButtonStyle(context),
            leadingIcon: item.leading,
            trailingIcon: item.value == selected
                ? const Icon(CupertinoIcons.checkmark_alt,
                    size: AppSizes.iconSmall)
                : null,
            onPressed: () => onChanged(item.value),
            child: Text(item.label),
          ),
      ],
      builder: (context, controller, child) => _Trigger(
        item: current,
        minWidth: minWidth,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _Trigger<T> extends StatelessWidget {
  const _Trigger({
    required this.item,
    required this.minWidth,
    required this.onTap,
  });

  final AppDropdownItem<T> item;
  final double minWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: AppSizes.controlHeight,
        maxHeight: AppSizes.controlHeight,
      ),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        clipBehavior: Clip.antiAlias,
        shape: StadiumBorder(side: BorderSide(color: colorScheme.outline)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.spacing12,
              right: AppSizes.spacing10,
            ),
            child: Row(
              // min + spaceBetween: the field is as narrow as its label
              // allows, and when [minWidth] makes it wider the arrow stays
              // pinned to the right edge instead of trailing the label.
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.leading != null) ...[
                        item.leading!,
                        const SizedBox(width: AppSizes.spacing8),
                      ],
                      Flexible(
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: AppSizes.iconSmall,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
