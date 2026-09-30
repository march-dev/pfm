import 'package:flutter/material.dart';

import '../placeholders/empty_placeholder.dart';
import 'labeled_progress_bar.dart';

/// The top [maxRows] entries of [counts] (by count, descending) as
/// [LabeledProgressBar] rows scaled relative to the largest one — or an
/// [EmptyPlaceholder] when there's nothing to count.
class RankedBreakdownList<T> extends StatelessWidget {
  const RankedBreakdownList({
    super.key,
    required this.counts,
    required this.iconAssetOf,
    required this.fallbackIconOf,
    required this.labelOf,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.countLabelOf = _defaultCountLabel,
    this.maxRows = 5,
    this.barHeight = 8,
  });

  final Map<T, int> counts;
  final String? Function(T) iconAssetOf;
  final IconData Function(T) fallbackIconOf;
  final String Function(T) labelOf;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  /// Formats each shown entry's own value for display (e.g. a plain
  /// count, or — passing [formatBytes] — a byte size). Defaults to the
  /// plain integer, unformatted.
  final String Function(int) countLabelOf;
  final int maxRows;
  final double barHeight;

  static const _rowAnimationDuration = Duration(milliseconds: 300);
  static const _rowSpacing = 8.0;
  // Fixed rather than measured — each row's own natural content (a 14px
  // icon and a bodySmall label) sits comfortably within this, with a
  // little breathing room either side. A fixed height is what lets rows
  // below use Stack/AnimatedPositioned to animate a rank change smoothly
  // — see build()'s own doc.
  static const _rowHeight = 22.0;

  static String _defaultCountLabel(int count) => '$count';

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return EmptyPlaceholder(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(maxRows).toList();
    final maxCount = shown.first.value;
    final totalHeight =
        shown.length * _rowHeight + (shown.length - 1) * _rowSpacing;

    // A Stack of AnimatedPositioned rows, not a plain Column — shown is
    // re-sorted by value every build, so a row's own rank can change
    // from one refresh to the next. A Column has no notion of "this was
    // row 3, now it's row 1" — it just lays out whatever's in the list
    // in that order, so a rank change would otherwise make a row
    // teleport to its new slot instead of sliding there, same reasoning
    // as CompositionBar's own segments.
    //
    // width: double.infinity (not a LayoutBuilder around this, the way
    // CompositionBar gets its own numeric width) — every row here only
    // ever needs to fill whatever width it's given (left: 0, right: 0
    // below already does that without knowing the number), and this
    // widget is used inside dashboard.screen.dart's own IntrinsicHeight
    // (for its two Distribution cards' equal-height row) — LayoutBuilder
    // categorically refuses intrinsic-dimension queries, which
    // IntrinsicHeight needs, and throws if asked; a plain SizedBox with
    // a real fixed height (totalHeight) answers that query directly
    // without even reaching this subtree.
    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            AnimatedPositioned(
              key: ValueKey(labelOf(shown[i].key)),
              duration: _rowAnimationDuration,
              curve: Curves.easeOutCubic,
              top: i * (_rowHeight + _rowSpacing),
              left: 0,
              right: 0,
              height: _rowHeight,
              child: LabeledProgressBar(
                iconAsset: iconAssetOf(shown[i].key),
                fallbackIcon: fallbackIconOf(shown[i].key),
                label: labelOf(shown[i].key),
                countLabel: countLabelOf(shown[i].value),
                fraction: shown[i].value / maxCount,
                height: barHeight,
              ),
            ),
        ],
      ),
    );
  }
}
