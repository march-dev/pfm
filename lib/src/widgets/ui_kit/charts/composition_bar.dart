import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../badges/color_dot.dart';
import '../context_menu/context_menu.dart';
import '../indicators/shimmer.dart';
import '../placeholders/empty_placeholder.dart';
import '../popovers/hover_popover.dart';

/// A GitHub-repo-language-bar-style breakdown of [counts]: one thin,
/// rounded, stacked bar with a segment per entry sized by its share of the
/// total, and a legend underneath (a coloured dot, its label, and its
/// percentage) — rather than [RankedBreakdownList]'s icon+label+progress-bar
/// rows, which read more like a settings list than "this project is made
/// of these languages/frameworks, in these proportions".
class CompositionBar<T> extends StatelessWidget {
  const CompositionBar({
    super.key,
    required this.counts,
    required this.colorOf,
    required this.labelOf,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.valueLabelOf,
    this.onLegendTap,
    this.isSelected,
    this.maxLegendEntries = 8,
    this.barHeight = 10,
    this.loading = false,
  });

  final Map<T, int> counts;
  final Color Function(T) colorOf;
  final String Function(T) labelOf;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  /// When given (e.g. passing [formatBytes]), hovering a legend entry
  /// shows this in a popover — the legend itself stays percentage-only,
  /// this is just the on-demand raw value behind it. Null (the default)
  /// means no popover at all.
  final String Function(int)? valueLabelOf;

  /// When given, each legend entry becomes clickable, calling this with
  /// its own key — e.g. tapping "npm" in a category breakdown to select
  /// only npm's own entries. Null (the default) keeps the legend
  /// non-interactive.
  final ValueChanged<T>? onLegendTap;

  /// When given (alongside [onLegendTap]), highlights whichever legend
  /// entry this returns true for — e.g. the category/safety level
  /// [onLegendTap] most recently toggled on — with a filled background/
  /// border in that entry's own colour, rather than the tappable legend
  /// giving no visual sign of which one (if any) is currently the active
  /// filter. Null (the default) means no entry is ever highlighted.
  final bool Function(T)? isSelected;
  final int maxLegendEntries;
  final double barHeight;

  /// True while [counts] is empty only because real data hasn't arrived
  /// yet (a cold, no-cache load) rather than because there's genuinely
  /// nothing to report — shows a shimmering placeholder bar instead of
  /// [EmptyPlaceholder] for as long as that's the case. Ignored once
  /// [counts] has anything in it.
  final bool loading;

  static const _minSegmentWidth = 10.0;
  static const _segmentGap = 1.0;
  static const _segmentAnimationDuration = Duration(milliseconds: 300);

  // Same background frame [SizeBar] draws around its own two segments —
  // a visible border/backdrop behind the gaps between this bar's segments
  // too, rather than just showing whatever's behind the card through them.
  static const _framePadding = AppSizes.spacing2;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      if (loading) {
        return _CompositionBarSkeleton(barHeight: barHeight);
      }
      return EmptyPlaceholder(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(maxLegendEntries).toList();
    final total = shown.fold<int>(0, (sum, entry) => sum + entry.value);
    final colorScheme = Theme.of(context).colorScheme;
    final outerHeight = barHeight + _framePadding * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: outerHeight,
          padding: const EdgeInsets.all(_framePadding),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(outerHeight / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _segmentWidths(
                counts: [for (final entry in shown) entry.value],
                barWidth: constraints.maxWidth,
                minWidth: _minSegmentWidth,
                gap: _segmentGap,
              );
              // Each segment's own left edge — a running sum of every
              // earlier segment's width plus its gap, rather than
              // leaving positioning to a Row's own left-to-right flex
              // layout (see below for why that isn't enough on its own).
              final lefts = List<double>.filled(widths.length, 0);
              var cursor = 0.0;
              for (var i = 0; i < widths.length; i++) {
                lefts[i] = cursor;
                cursor += widths[i] + _segmentGap;
              }

              // A Stack of AnimatedPositioned, not a Row — shown is
              // re-sorted by value every build, so a segment's own rank
              // (and thus which slot it belongs in) can change from one
              // refresh to the next as data streams in. A Row keyed by
              // label already animates each segment's own width/colour
              // smoothly across such a change (Flutter matches by key
              // regardless of list order), but it still lays out
              // strictly by current list order — a segment that jumps
              // rank teleports straight to its new slot instead of
              // sliding there. AnimatedPositioned instead interpolates
              // left/width explicitly, keyed the same way, so a rank
              // change slides a segment to its new position exactly
              // like a value change resizes it.
              //
              // Explicit size on the Stack itself — with every child
              // Positioned (none left to size by), a loose Stack would
              // otherwise collapse to zero rather than filling the bar.
              return SizedBox(
                width: constraints.maxWidth,
                height: barHeight,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      AnimatedPositioned(
                        key: ValueKey(labelOf(shown[i].key)),
                        duration: _segmentAnimationDuration,
                        curve: Curves.easeOutCubic,
                        left: lefts[i],
                        width: widths[i],
                        top: 0,
                        height: barHeight,
                        child: AnimatedContainer(
                          duration: _segmentAnimationDuration,
                          curve: Curves.easeOutCubic,
                          // Rounded the same way the outer frame rounds
                          // the bar's own two ends — every segment reads
                          // as its own small pill rather than a sharp-
                          // cornered block, and a segment pinned to
                          // _minSegmentWidth (exactly as wide as the bar
                          // is tall) rounds all the way into a circle.
                          // A ring around whichever segment's own legend
                          // entry is currently selected (see _LegendEntry's
                          // own doc) — otherwise the bar itself gave no
                          // sign of which segment a selected legend chip
                          // even corresponds to.
                          decoration: BoxDecoration(
                            color: colorOf(shown[i].key),
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            border: (isSelected?.call(shown[i].key) ?? false)
                                ? Border.all(
                                    color: _selectedVariant(
                                      context,
                                      colorOf(shown[i].key),
                                    ),
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: AppSizes.spacing12,
          runSpacing: AppSizes.spacing6,
          children: [
            for (final entry in shown)
              _LegendEntry(
                color: colorOf(entry.key),
                label: labelOf(entry.key),
                valueLabel: valueLabelOf?.call(entry.value),
                fraction: entry.value / total,
                onTap:
                    onLegendTap == null ? null : () => onLegendTap!(entry.key),
                selected: isSelected?.call(entry.key) ?? false,
              ),
          ],
        ),
      ],
    );
  }
}

// A variation of [color] itself — used for a "selected" ring/border,
// rather than an unrelated neutral (e.g. colorScheme.onSurface), so the
// highlight still reads as "this same segment, emphasized" instead of a
// generic selection outline that could belong to any widget. Lightens in
// dark mode, darkens in light mode — a single fixed direction (always
// darker) reads fine against a light background, but on a dark one it
// can push an already-dark segment colour (a deep blue/purple, say) so
// close to the surrounding dark chrome that the ring becomes nearly
// invisible; moving away from the middle in whichever direction
// increases contrast against the *current* theme keeps every colour
// legible in both.
Color _selectedVariant(BuildContext context, Color color) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(color);
  final lightness = isDark
      ? (hsl.lightness + 0.3).clamp(0.0, 0.92)
      : (hsl.lightness - 0.3).clamp(0.08, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// Resolves each segment's pixel width so every one of [counts] gets at
/// least [minWidth], with [gap] left between adjacent segments — rather
/// than a plain proportional (flex) split, which lets a small enough share
/// shrink below any legible width once enough other segments crowd it out.
///
/// Segments that would fall below [minWidth] are pinned to it; what's left
/// of [barWidth] is then split, in proportion to their own counts, among
/// the rest — repeated (pinning can only ever free up width for the
/// segments still unpinned, never take more away) until nothing further
/// drops below the minimum.
List<double> _segmentWidths({
  required List<int> counts,
  required double barWidth,
  required double minWidth,
  required double gap,
}) {
  final n = counts.length;
  final widths = List<double>.filled(n, 0);
  if (n == 0) return widths;

  final fixed = List<bool>.filled(n, false);
  var remainingWidth = (barWidth - gap * (n - 1)).clamp(0, double.infinity);
  var remainingTotal = counts.fold<int>(0, (sum, count) => sum + count);

  var changed = true;
  while (changed) {
    changed = false;
    for (var i = 0; i < n; i++) {
      if (fixed[i]) continue;
      final share = remainingTotal > 0
          ? remainingWidth * counts[i] / remainingTotal
          : 0.0;
      if (share < minWidth && remainingWidth > 0) {
        widths[i] = minWidth;
        fixed[i] = true;
        remainingWidth -= minWidth;
        remainingTotal -= counts[i];
        changed = true;
      }
    }
  }
  for (var i = 0; i < n; i++) {
    if (!fixed[i]) {
      widths[i] =
          remainingTotal > 0 ? remainingWidth * counts[i] / remainingTotal : 0;
    }
  }
  return widths;
}

// Shown in place of [CompositionBar]'s own bar+legend while [counts] is
// still empty only because a cold load hasn't reported anything yet (see
// CompositionBar.loading's own doc) — shaped like the real thing (a bar
// plus a couple of legend chips) so it reads as "still loading" rather
// than the genuinely-empty EmptyPlaceholder it'd otherwise show.
class _CompositionBarSkeleton extends StatelessWidget {
  const _CompositionBarSkeleton({required this.barHeight});

  final double barHeight;

  static const _framePadding = CompositionBar._framePadding;
  static const _legendChipWidths = [64.0, 48.0, 72.0];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outerHeight = barHeight + _framePadding * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer(
          child: Container(
            height: outerHeight,
            decoration: BoxDecoration(
              color: colorScheme.onSurface,
              borderRadius: BorderRadius.circular(outerHeight / 2),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: AppSizes.spacing12,
          runSpacing: AppSizes.spacing6,
          children: [
            for (final width in _legendChipWidths)
              Shimmer(
                child: Container(
                  width: width,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.onTap,
    required this.selected,
  });

  final Color color;
  final String label;
  final String? valueLabel;
  final double fraction;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // A genuinely nonzero share can still round to "0.0%" at one decimal
    // place (anything under 0.05%) — reads as if it rounded all the way
    // down to nothing, when there's really a sliver still there; "<0.1%"
    // says so instead.
    final rounded = (fraction * 100).toStringAsFixed(1);
    final percent = (fraction > 0 && rounded == '0.0') ? '<0.1%' : '$rounded%';

    Widget entry = _LegendRow(
      color: color,
      label: label,
      percent: percent,
      selected: selected,
    );

    final onTap = this.onTap;
    if (onTap != null) entry = _TappableLegend(onTap: onTap, child: entry);

    if (selected) {
      entry = DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: entry,
      );
    }

    final valueLabel = this.valueLabel;
    if (valueLabel == null) return entry;

    return HoverPopover(
      popoverBuilder: (context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing10,
          vertical: AppSizes.spacing6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: menuBorderColor),
        ),
        child: Text(valueLabel, style: Theme.of(context).textTheme.bodySmall),
      ),
      child: entry,
    );
  }
}

// The dot+label+percent itself — its own leaf widget class (rather than
// a locally-built Row threaded through the wrappers above) purely to
// keep _LegendEntry.build within this file's own widget-nesting budget.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.selected,
  });

  final Color color;
  final String label;
  final String percent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorDot(color: color),
        const SizedBox(width: AppSizes.spacing6),
        Text(
          '$label $percent',
          // Colour-only difference when selected — no fontWeight change:
          // bold glyphs measure wider than regular ones for the same
          // string, so toggling it on/off was visibly widening/
          // narrowing this whole legend entry (and everything after it
          // in the Wrap) each time, purely from the text itself
          // reflowing.
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}

// Makes a legend entry clickable — e.g. selecting only that segment's
// own entries — its own leaf widget purely to keep _LegendEntry.build
// within this file's own widget-nesting budget.
class _TappableLegend extends StatelessWidget {
  const _TappableLegend({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing4,
            vertical: AppSizes.spacing2,
          ),
          child: child,
        ),
      ),
    );
  }
}
