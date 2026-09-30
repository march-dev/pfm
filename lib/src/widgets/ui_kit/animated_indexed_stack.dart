import 'package:flutter/material.dart';

/// Same contract as [IndexedStack] — every one of [children] stays mounted
/// (and whatever [Provider]/store/scroll position it owns stays alive) the
/// whole time, only [index] ever changes which one is actually visible —
/// except switching [index] crossfades between the old and new child
/// instead of snapping between them.
///
/// [IndexedStack] itself has no notion of animating that switch; this
/// layers a fade on top by keeping the previous index's own child visible
/// (fading out) right alongside the new one (fading in) for [duration],
/// via a plain [Stack] instead — every other child stays exactly as
/// invisible/un-painted as [IndexedStack] already left them.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.index;
    // Starts at 1 (fully settled on the initial index) — there's no
    // earlier tab to fade from on first build.
    _controller =
        AnimationController(vsync: this, duration: widget.duration, value: 1);
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previousIndex = oldWidget.index;
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++) _buildChild(i),
        ],
      ),
    );
  }

  Widget _buildChild(int i) {
    final isCurrent = i == widget.index;
    final isPrevious = i == _previousIndex && _previousIndex != widget.index;

    final opacity = isCurrent
        ? _controller.value
        : isPrevious
            ? 1 - _controller.value
            : 0.0;

    return IgnorePointer(
      // Only the incoming tab is ever interactive — same as IndexedStack's
      // own all-or-nothing behaviour, just with the outgoing one fading
      // out underneath instead of disappearing outright.
      ignoring: !isCurrent,
      child: Offstage(
        offstage: opacity == 0,
        child: Opacity(opacity: opacity, child: widget.children[i]),
      ),
    );
  }
}
