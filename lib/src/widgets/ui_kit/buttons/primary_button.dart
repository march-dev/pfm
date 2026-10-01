import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../indicators/loading_spinner.dart';

/// A filled icon+label button whose icon swaps to a [LoadingSpinner] while
/// [loading] — e.g. a "Clean All" action that takes a moment to complete.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    this.loading = false,
    this.disabled = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final Color backgroundColor;
  final Color? foregroundColor;

  /// Swaps [icon] for a spinner and disables the button, for an action
  /// currently in flight.
  final bool loading;

  /// Disables the button for any other reason (independent of [loading]).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: (loading || disabled) ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
        disabledForegroundColor: foregroundColor?.withValues(alpha: 0.6),
        // Without this, the label falls back to the theme's own
        // labelLarge — repurposed app-wide (see AppTypography) as a tiny
        // 10px caption style, not a button label — reading far smaller
        // than every other button in the app. titleSmall matches
        // SplitButton's own label style, so every button-like control
        // reads at the same size/weight.
        textStyle: Theme.of(context).textTheme.titleSmall,
        // Material's default button is 40px tall; every control in a row
        // shares AppSizes.controlHeight instead.
        minimumSize: const Size(0, AppSizes.controlHeight),
        maximumSize: const Size(double.infinity, AppSizes.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Same reasoning as CircleIconButton's own icon/spinner swap — a
      // plain ternary between two different widget types can't animate on
      // its own, so this crossfades between them instead of snapping.
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: loading
            ? const LoadingSpinner(key: ValueKey('spinner'))
            : KeyedSubtree(key: const ValueKey('icon'), child: icon),
      ),
      label: label,
    );
  }
}
