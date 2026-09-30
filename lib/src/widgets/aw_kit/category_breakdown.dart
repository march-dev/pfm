import 'package:flutter/material.dart';

import '../../../pfm.dart';

/// One row per expense category: color dot, name, a bar scaled against the
/// largest, the amount and its share of the month's spending.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.entries,
    required this.totalCents,
  });

  /// Largest first.
  final List<MapEntry<CategoryModel, int>> entries;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final largest = entries.first.value;

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing6),
            child: _Row(
              category: entry.key,
              cents: entry.value,
              fraction: largest <= 0 ? 0 : entry.value / largest,
              share: totalCents <= 0 ? 0 : entry.value / totalCents,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.category,
    required this.cents,
    required this.fraction,
    required this.share,
  });

  final CategoryModel category;
  final int cents;
  final double fraction;
  final double share;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Icon(categoryIcon(category), size: AppSizes.iconSmall, color: category.color),
        const SizedBox(width: AppSizes.spacing8),
        SizedBox(
          width: 130,
          child: Text(
            categoryLabel(l10n, category),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: Stack(
              children: [
                Container(height: 8, color: colorScheme.outlineVariant),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction.clamp(0, 1)),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 8, color: category.color),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        SizedBox(
          width: 92,
          child: Text(
            formatCents(cents),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${(share * 100).round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
