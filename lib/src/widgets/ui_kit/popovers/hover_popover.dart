import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../context_menu/context_menu.dart';

/// Shows [popoverBuilder]'s content in a floating overlay while the mouse
/// hovers [child] (or the popover itself) — for content too rich for
/// [Tooltip]'s plain-text-only `message`/`richMessage` (e.g. a wrapped
/// grid of icon+label chips), where a bespoke widget is worth it over a
/// long comma-separated sentence.
///
/// There's a short grace period before actually hiding, rather than
/// closing the instant the pointer leaves [child] — otherwise moving the
/// mouse across the small gap from [child] to the popover itself (they're
/// not touching, since the popover floats slightly below it) would close
/// it before the pointer ever reaches the content.
///
/// Position is computed fresh each time the popover opens — centered
/// under [child] and flush below it by default — then adjusted by
/// [_PopoverLayoutDelegate] so it never runs off the window: it shifts
/// sideways to clear the left/right edges, and opens above [child]
/// instead when there isn't room below.
class HoverPopover extends StatefulWidget {
  const HoverPopover({
    super.key,
    required this.child,
    required this.popoverBuilder,
  });

  final Widget child;
  final WidgetBuilder popoverBuilder;

  @override
  State<HoverPopover> createState() => _HoverPopoverState();
}

class _HoverPopoverState extends State<HoverPopover>
    with SingleTickerProviderStateMixin {
  final _controller = OverlayPortalController();
  final _anchorKey = GlobalKey();
  Timer? _hideTimer;

  // OverlayPortalController.show()/hide() hard mount/unmount the overlay
  // child — no fade of their own. This drives an actual fade in/out
  // around that: show() forwards it (mounting first, if not already
  // shown, so there's something to fade in); a scheduled hide reverses it
  // and only actually calls _controller.hide() once fully faded out —
  // otherwise there'd be nothing left on screen to animate.
  //
  // Built eagerly in initState (not `late final` initialized on first
  // use) — a popover that's never actually hovered never reads this
  // anywhere else, so a lazy initializer would only ever run for the
  // first time inside dispose(), constructing an AnimationController
  // (vsync: this) against an element that's already deactivating by
  // then, which is unsafe (TickerMode's own ancestor lookup asserts on
  // exactly this).
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  void _show() {
    _hideTimer?.cancel();
    if (!_controller.isShowing) _controller.show();
    _fadeController.forward();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), () {
      _fadeController.reverse().whenComplete(() {
        // Guards against a _show() that interrupted this same reverse
        // (re-entering before it finished) — that leaves the controller
        // mid- or fully-forward by the time this fires, not dismissed,
        // meaning the popover is meant to still be showing.
        if (mounted && _fadeController.status == AnimationStatus.dismissed) {
          _controller.hide();
        }
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _show(),
      onExit: (_) => _scheduleHide(),
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) => FadeTransition(
          opacity: _fadeController,
          child: _PositionedPopover(
            anchorKey: _anchorKey,
            onEnter: _show,
            onExit: _scheduleHide,
            builder: widget.popoverBuilder,
          ),
        ),
        // Keyed so _anchorKey.currentContext keeps resolving to this
        // exact child's own RenderBox across rebuilds, not a freshly
        // recreated one.
        child: KeyedSubtree(key: _anchorKey, child: widget.child),
      ),
    );
  }
}

/// Reads [anchorKey]'s current global position/size and lays the popover
/// (plus its own little pointer triangle — see [_PopoverArrow]) out
/// relative to it via [_PopoverLayoutDelegate] — split out purely so
/// [_HoverPopoverState.build] doesn't have to reason about the layout
/// math directly.
class _PositionedPopover extends StatelessWidget {
  const _PositionedPopover({
    required this.anchorKey,
    required this.onEnter,
    required this.onExit,
    required this.builder,
  });

  final GlobalKey anchorKey;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final anchorBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    // Not yet laid out (this can only happen for one throwaway frame
    // right as the popover first opens) — nothing sensible to position
    // against yet.
    if (anchorBox == null || !anchorBox.hasSize) return const SizedBox.shrink();

    final anchorRect = anchorBox.localToGlobal(Offset.zero) & anchorBox.size;

    return CustomMultiChildLayout(
      delegate: _PopoverLayoutDelegate(anchorRect: anchorRect),
      children: [
        LayoutId(
          id: _PopoverSlot.content,
          // Its own MouseRegion so hovering into the popover (rather
          // than back onto child) also cancels the pending hide.
          child: MouseRegion(
            onEnter: (_) => onEnter(),
            onExit: (_) => onExit(),
            child: builder(context),
          ),
        ),
        // Both orientations are always built — cheap, tiny CustomPaints —
        // rather than deciding which single one to build here, since
        // "which side has room" isn't known until the content itself has
        // been measured, which only happens inside the very layout pass
        // that positions everything (see the delegate's own doc). It
        // hides whichever one it didn't pick by giving it zero size.
        LayoutId(
          id: _PopoverSlot.arrowUp,
          child: const _PopoverArrow(pointingUp: true),
        ),
        LayoutId(
          id: _PopoverSlot.arrowDown,
          child: const _PopoverArrow(pointingUp: false),
        ),
      ],
    );
  }
}

enum _PopoverSlot { content, arrowUp, arrowDown }

/// Centers the popover under [anchorRect] by default, then shifts/flips it
/// so it always stays fully within the window: [size] here is the whole
/// window (OverlayPortal always lays its overlay child out tight to the
/// full app window — see the framework's own overlay.dart), so clamping
/// against it is equivalent to clamping against the screen.
///
/// Also positions a small triangle pointing from whichever edge of the
/// popover sits nearest [anchorRect] back toward it (see [_PopoverArrow])
/// — its own horizontal position (and which of the two, up- or down-
/// pointing, is the one actually shown) both depend on the content's own
/// measured size, which is why this is one [MultiChildLayoutDelegate]
/// positioning both rather than the arrow being laid out independently.
class _PopoverLayoutDelegate extends MultiChildLayoutDelegate {
  _PopoverLayoutDelegate({required this.anchorRect});

  final Rect anchorRect;

  static const _gap = 8.0;
  static const _edgeMargin = 8.0;

  // Keeps the arrow clear of the popover's own rounded corners rather
  // than letting it slide all the way to an edge and looking like it's
  // falling off the box.
  static const _arrowInset = 12.0;

  @override
  void performLayout(Size size) {
    final contentSize = layoutChild(
      _PopoverSlot.content,
      BoxConstraints.loose(size),
    );

    final dx = (anchorRect.center.dx - contentSize.width / 2)
        .clamp(
          _edgeMargin,
          math.max(_edgeMargin, size.width - contentSize.width - _edgeMargin),
        )
        .toDouble();

    final fitsBelow =
        anchorRect.bottom + _gap + contentSize.height <= size.height;
    final dy = fitsBelow
        ? anchorRect.bottom + _gap
        : (anchorRect.top - _gap - contentSize.height)
            .clamp(
              _edgeMargin,
              math.max(
                  _edgeMargin, size.height - contentSize.height - _edgeMargin),
            )
            .toDouble();

    positionChild(_PopoverSlot.content, Offset(dx, dy));

    final arrowUpSize =
        layoutChild(_PopoverSlot.arrowUp, const BoxConstraints());
    final arrowDownSize =
        layoutChild(_PopoverSlot.arrowDown, const BoxConstraints());
    final visibleSlot =
        fitsBelow ? _PopoverSlot.arrowUp : _PopoverSlot.arrowDown;
    final visibleSize = fitsBelow ? arrowUpSize : arrowDownSize;

    final minArrowDx = dx + _arrowInset;
    final maxArrowDx = math.max(
      minArrowDx,
      dx + contentSize.width - visibleSize.width - _arrowInset,
    );
    final arrowDx = (anchorRect.center.dx - visibleSize.width / 2)
        .clamp(minArrowDx, maxArrowDx)
        .toDouble();
    // Overlapping content's own edge by a pixel — otherwise the arrow's
    // flat base and the popover box's own border, drawn a frame apart by
    // two separate render objects, can leave a hairline gap between them.
    final arrowDy =
        fitsBelow ? dy - visibleSize.height + 1 : dy + contentSize.height - 1;

    positionChild(visibleSlot, Offset(arrowDx, arrowDy));
    positionChild(
      fitsBelow ? _PopoverSlot.arrowDown : _PopoverSlot.arrowUp,
      Offset.zero,
    );
  }

  @override
  bool shouldRelayout(covariant _PopoverLayoutDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect;
}

/// A small triangle pointing up (toward an anchor above the popover) or
/// down (toward one below it) — colour-matched to every [HoverPopover]
/// caller's own popover box (`surfaceContainerHighest` background,
/// [menuBorderColor] border — the one convention every current
/// popoverBuilder already follows), so it reads as a notch pulled out of
/// the box itself rather than a separate decoration.
class _PopoverArrow extends StatelessWidget {
  const _PopoverArrow({required this.pointingUp});

  final bool pointingUp;

  static const width = 14.0;
  static const height = 7.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PopoverArrowPainter(
          pointingUp: pointingUp,
          color: colorScheme.surfaceContainerHighest,
          borderColor: menuBorderColor,
        ),
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  const _PopoverArrowPainter({
    required this.pointingUp,
    required this.color,
    required this.borderColor,
  });

  final bool pointingUp;
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Only the two slanted sides are stroked (a separate, open path from
    // the filled triangle) — stroking the flat base too would draw a
    // visible seam right where it overlaps the popover box's own border.
    final apex = Offset(size.width / 2, pointingUp ? 0 : size.height);
    final baseLeft = Offset(0, pointingUp ? size.height : 0);
    final baseRight = Offset(size.width, pointingUp ? size.height : 0);

    final fillPath = Path()
      ..moveTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = color);

    final strokePath = Path()
      ..moveTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(baseRight.dx, baseRight.dy);
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PopoverArrowPainter oldDelegate) =>
      oldDelegate.pointingUp != pointingUp ||
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor;
}
