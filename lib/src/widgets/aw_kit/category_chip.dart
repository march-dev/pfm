import 'package:flutter/material.dart';

import '../../../pfm.dart';

/// A category as a small tinted pill: its color dot and name. With [onTap]
/// it reads as a button (the Transactions table uses that to open the
/// assign dialog); [pinned] marks a category the user set by hand for this
/// one transaction, as opposed to one the rules worked out.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
    this.pinned = false,
    this.selected = false,
  });

  final CategoryModel category;
  final VoidCallback? onTap;
  final bool pinned;

  /// Highlights the pill with a border in the category's own color — for a
  /// chip standing in a "pick one" set.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: selected ? category.color : Colors.transparent,
          width: AppSizes.borderWidth * 1.5,
        ),
      ),
      child: PillBadge(
        onTap: onTap,
        color: category.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium - 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing8,
          vertical: AppSizes.spacing4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorDot(color: category.color, size: 8),
            const SizedBox(width: AppSizes.spacing6),
            Flexible(
              child: Text(
                categoryLabel(l10n, category),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (pinned) ...[
              const SizedBox(width: AppSizes.spacing4),
              Tooltip(
                message: l10n.pinnedHint,
                child: Icon(
                  Icons.push_pin,
                  size: AppSizes.iconTiny,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
