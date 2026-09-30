import 'package:flutter/material.dart';

import '../icons/asset_or_fallback_icon.dart';

/// One row of a [RankedBreakdownList]: an icon, a label, a proportional
/// progress bar, and the value it represents (already formatted).
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    required this.countLabel,
    required this.fraction,
    this.height = 8,
    this.labelWidth = 130,
    this.countWidth = 28,
  });

  final String? iconAsset;
  final IconData fallbackIcon;
  final String label;

  /// This row's own value, already formatted for display (e.g. a plain
  /// count, or a formatted byte size) — [RankedBreakdownList] decides how.
  final String countLabel;

  /// This row's proportion of the largest row currently shown, in `[0, 1]`.
  final double fraction;
  final double height;
  final double labelWidth;
  final double countWidth;

  static const _fractionAnimationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            children: [
              AssetOrFallbackIcon(
                iconAsset: iconAsset,
                fallbackIcon: fallbackIcon,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              _ProgressBarLabel(label: label, color: colorScheme.onSurface),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            // A plain LinearProgressIndicator has no animation of its own —
            // changing its value between rebuilds just snaps to the new
            // fill instantly. TweenAnimationBuilder retargets smoothly
            // from wherever it currently sits to the new fraction each
            // time this rebuilds with a different one, the same way
            // AnimatedContainer/AnimatedPositioned do elsewhere — begin's
            // value here only ever matters for this row's very first
            // frame (0, so a brand-new row grows in rather than
            // appearing already full).
            child: TweenAnimationBuilder<double>(
              key: ValueKey(label),
              tween: Tween(begin: 0, end: fraction),
              duration: _fractionAnimationDuration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedFraction, child) =>
                  LinearProgressIndicator(
                value: animatedFraction,
                minHeight: height,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
          ),
        ),
        SizedBox(
          width: countWidth,
          child: Text(
            countLabel,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}

/// The label's ellipsizing text, split out purely to keep
/// [LabeledProgressBar.build] within this file's own widget-nesting budget.
class _ProgressBarLabel extends StatelessWidget {
  const _ProgressBarLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
      ),
    );
  }
}
