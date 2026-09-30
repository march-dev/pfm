import 'package:flutter/material.dart';

/// A drop-in replacement for a plain `ListView.builder`/`Column` of [items]
/// that actually animates insertions and removals — Flutter's own
/// [AnimatedList] does this, but only if something explicitly tells it
/// *which* index was inserted/removed; it never diffs an old list against a
/// new one on its own. This widget does that diffing itself (by [keyOf]'s
/// own identity, via a longest-common-subsequence comparison against
/// whatever [items] looked like last build) and drives an internal
/// [AnimatedList] accordingly, so every list in the app that swaps this in
/// gets real insert/remove transitions for free just by continuing to pass
/// whatever `List<T>` it already had.
///
/// A key present in both the old and new [items] is treated as "the same
/// item, possibly updated" (no animation, just re-rendered in place) even
/// if its value changed — only genuinely new/vanished keys animate.
/// Reordering existing items (e.g. a resort) is expressed as a remove-then-
/// insert pair, the same as any other list-diffing UI does, since
/// [AnimatedList] itself has no separate "move" animation.
class AnimatedDiffList<T> extends StatefulWidget {
  const AnimatedDiffList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.keyOf,
    this.separatorBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.controller,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 250),
  });

  final List<T> items;

  /// Builds one item's own content — no divider, no animation wrapper;
  /// both are applied around whatever this returns.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// This item's own stable identity across rebuilds (e.g. a project's
  /// path) — required, not optional: without a real identity there's
  /// nothing to diff against, and every rebuild would look like "remove
  /// everything, insert everything" (no animation at all, just a flash).
  final Object Function(T item) keyOf;

  /// When given, rendered between adjacent items (never before the first
  /// or after the last) — e.g. a [HairlineDivider]. Not shown below an
  /// item mid-removal, which reads fine since the row itself is shrinking
  /// away regardless.
  final Widget Function(BuildContext context)? separatorBuilder;

  /// True for a list embedded inside an already-scrolling ancestor (sized
  /// to its own content instead of owning a scroll viewport) — same
  /// meaning as [ScrollView.shrinkWrap].
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Duration insertDuration;
  final Duration removeDuration;

  @override
  State<AnimatedDiffList<T>> createState() => _AnimatedDiffListState<T>();
}

class _AnimatedDiffListState<T> extends State<AnimatedDiffList<T>> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant AnimatedDiffList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items)) _applyDiff(widget.items);
  }

  // Reconciles [_items] (what the AnimatedList currently shows) toward
  // [newItems] via a longest-common-subsequence edit script over their
  // own keys — the standard "diff to a sequence of inserts/removes"
  // approach, applied directly against the live AnimatedListState rather
  // than computed as a separate patch object first, since each
  // insert/remove has to happen at the index [_items] holds *at that
  // exact moment*, which shifts as earlier ops in the same script apply.
  void _applyDiff(List<T> newItems) {
    final oldKeys = _items.map(widget.keyOf).toList();
    final newKeys = newItems.map(widget.keyOf).toList();
    final m = oldKeys.length;
    final n = newKeys.length;

    // dp[i][j] = length of the LCS of oldKeys[i:] and newKeys[j:].
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = m - 1; i >= 0; i--) {
      for (var j = n - 1; j >= 0; j--) {
        dp[i][j] = oldKeys[i] == newKeys[j]
            ? dp[i + 1][j + 1] + 1
            : (dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    var i = 0, j = 0, index = 0;
    while (i < m || j < n) {
      if (i < m && j < n && oldKeys[i] == newKeys[j]) {
        _items[index] = newItems[j];
        i++;
        j++;
        index++;
      } else if (j < n && (i >= m || dp[i][j + 1] >= dp[i + 1][j])) {
        final item = newItems[j];
        _items.insert(index, item);
        _listKey.currentState
            ?.insertItem(index, duration: widget.insertDuration);
        j++;
        index++;
      } else {
        final removed = _items.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) =>
              _wrap(context, removed, animation, isLast: true),
          duration: widget.removeDuration,
        );
        i++;
      }
    }
  }

  Widget _wrap(
    BuildContext context,
    T item,
    Animation<double> animation, {
    required bool isLast,
  }) {
    final content = SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axis: Axis.vertical,
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, item),
      ),
    );

    final separatorBuilder = widget.separatorBuilder;
    if (separatorBuilder == null || isLast) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [content, separatorBuilder(context)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      controller: widget.controller,
      itemBuilder: (context, index, animation) => _wrap(
        context,
        _items[index],
        animation,
        isLast: index == _items.length - 1,
      ),
    );
  }
}
