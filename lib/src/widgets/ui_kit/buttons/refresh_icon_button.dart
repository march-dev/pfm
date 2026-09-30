import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import 'circle_icon_button.dart';

/// A header refresh action — storage.screen.dart's and explorer.screen
/// .dart's own manual refresh button, and whichever screen picks this up
/// next. Spins the icon continuously while [refreshing] (whether triggered
/// by tapping this button or a silent background refresh elsewhere) and
/// disables taps for the duration, rather than swapping the icon for a
/// separate progress indicator.
class RefreshIconButton extends StatefulWidget {
  const RefreshIconButton({
    super.key,
    required this.refreshing,
    required this.onPressed,
    this.tooltip,
  });

  final bool refreshing;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<RefreshIconButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  // True once [widget.refreshing] turns false but the icon is still
  // coasting to the end of its current revolution (see didUpdateWidget)
  // — kept disabled for that same stretch too, same as [widget.
  // refreshing] itself, so a tap can't start a new spin while the old
  // one is still visibly wrapping up.
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.refreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RefreshIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing == oldWidget.refreshing) return;

    if (widget.refreshing) {
      if (_finishing) setState(() => _finishing = false);
      _controller.repeat();
      return;
    }

    // Already at a clean rest position (a turn boundary) — nothing to
    // finish, just stop outright.
    final fraction = _controller.value % 1.0;
    if (fraction == 0) {
      _controller.stop();
      _controller.value = 0;
      return;
    }

    // Coasts to the *next* turn boundary at the same speed it was
    // already spinning at, rather than snapping straight back to
    // upright from wherever mid-rotation it happened to be.
    final remaining = 1.0 - fraction;
    setState(() => _finishing = true);
    _controller
        .animateTo(
      _controller.value + remaining,
      duration: _controller.duration! * remaining,
    )
        .then((_) {
      // A new refresh could have already started mid-coast (e.g. a
      // background refresh re-triggering right as this one's own
      // finishing spin was about to land) — leave its own repeat()
      // alone rather than stomping on it.
      if (!mounted || widget.refreshing) return;
      _controller.value = 0;
      setState(() => _finishing = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.refreshing || _finishing;

    return CircleIconButton(
      onPressed: busy ? null : widget.onPressed,
      backgroundColor: Colors.transparent,
      tooltip: widget.tooltip,
      icon: RotationTransition(
        turns: _controller,
        // CupertinoIcons.refresh is two chasing arrows, which reads oddly
        // mid-spin — a single clockwise arrow is the shape actually meant
        // to be animated this way.
        child: const Icon(Icons.refresh_rounded, size: AppSizes.iconLarge),
      ),
    );
  }
}
