import 'package:flutter/material.dart';

/// The shared "zebra-striped, hoverable, tappable" row chrome used by every
/// table-like row in the app (a plain table row, a tree row, ...) — a
/// zebra-tinted background, secondary-tap detection, and a Material+InkWell
/// for the primary tap/double-tap/hover, wrapping arbitrary row content
/// that [builder] rebuilds on every hover change.
class HoverableRow extends StatefulWidget {
  const HoverableRow({
    super.key,
    required this.height,
    required this.builder,
    this.zebra = false,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTapUp,
  });

  final double height;
  final bool zebra;

  /// Builds this row's own content. [isHovered] reflects whether the
  /// pointer is currently over this row — e.g. for a cell that only shows
  /// extra content on hover.
  final Widget Function(BuildContext context, bool isHovered) builder;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  /// Given this row's own context (so a handler can look up its Overlay/
  /// Navigator, e.g. to show a context menu) and where the secondary click
  /// landed.
  final void Function(BuildContext context, Offset globalPosition)?
      onSecondaryTapUp;

  @override
  State<HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<HoverableRow> {
  bool _hovering = false;

  static const _hoverDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The zebra tint is a plain, hover-independent stripe — _hovering was
    // already tracked here (for builder's own content-level hover, e.g. a
    // trailing hint), but never fed into this row's own background, which
    // left InkWell's own default ripple overlay as the only hover
    // feedback the row's own chrome ever got. Blending _hovering into
    // this AnimatedContainer's own color gives every row (zebra or not) a
    // consistent, more visible tint on top of that, still with a real
    // transition rather than InkWell's default subtle/instant overlay.
    final baseColor = widget.zebra
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
        : Colors.transparent;
    final hoverColor = colorScheme.onSurface.withValues(alpha: 0.05);

    return AnimatedContainer(
      duration: _hoverDuration,
      color: _hovering ? Color.alphaBlend(hoverColor, baseColor) : baseColor,
      child: GestureDetector(
        onSecondaryTapUp: widget.onSecondaryTapUp == null
            ? null
            : (details) =>
                widget.onSecondaryTapUp!(context, details.globalPosition),
        child: _InkWellSurface(
          height: widget.height,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onHover: (hovering) => setState(() => _hovering = hovering),
          child: widget.builder(context, _hovering),
        ),
      ),
    );
  }
}

// The Material+InkWell+SizedBox trio that actually handles tap/double-tap/
// hover, factored out purely to keep _HoverableRowState.build within this
// file's own widget-nesting budget.
class _InkWellSurface extends StatelessWidget {
  const _InkWellSurface({
    required this.height,
    required this.onTap,
    required this.onDoubleTap,
    required this.onHover,
    required this.child,
  });

  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<bool> onHover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onHover: onHover,
        child: SizedBox(height: height, child: child),
      ),
    );
  }
}
