import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../context_menu/context_menu.dart';
import '../indicators/loading_spinner.dart';

/// One entry in a [SplitButton]'s dropdown.
class SplitButtonMenuItem<T> {
  const SplitButtonMenuItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A split button: the main body triggers [onPressed], while the chevron
/// opens a menu of [menuItems] — e.g. a primary action alongside a less
/// common variant of it (a recursive add, a "save as", ...), scoping that
/// choice to the action it modifies rather than it floating as an
/// unrelated control elsewhere on the page.
class SplitButton<T> extends StatelessWidget {
  const SplitButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.menuItems,
    required this.onMenuItemSelected,
    this.loading = false,
    this.disabled = false,
    this.menuTooltip,
    this.height = AppSizes.controlHeight,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final List<SplitButtonMenuItem<T>> menuItems;
  final ValueChanged<T> onMenuItemSelected;

  /// Swaps [icon] for a spinner and disables both the main body and the
  /// menu, for an action currently in flight.
  final bool loading;

  /// Disables both the main body and the menu for any other reason (e.g.
  /// nothing left [menuItems] could offer) — same effect as [loading] on
  /// interactivity, but fades the whole button instead of showing a
  /// spinner, so a caller doesn't have to swap this out for an entirely
  /// different widget just to represent "temporarily nothing to do here"
  /// (which otherwise reads as the button having vanished, not settled
  /// into a resting state).
  final bool disabled;
  final String? menuTooltip;
  final double height;

  /// Both default to the theme's primary color pairing.
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? colorScheme.primary;
    final foreground = foregroundColor ?? colorScheme.onPrimary;
    final interactive = !loading && !disabled;
    final effectiveBackground =
        disabled ? background.withValues(alpha: 0.5) : background;
    final effectiveForeground =
        disabled ? foreground.withValues(alpha: 0.6) : foreground;

    return Material(
      color: effectiveBackground,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(height / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: interactive ? onPressed : null,
            child: _SplitButtonContent(
              height: height,
              loading: loading,
              icon: icon,
              label: label,
              foreground: effectiveForeground,
            ),
          ),
          SizedBox(
            height: height * 0.6,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: effectiveForeground.withValues(alpha: 0.35),
            ),
          ),
          MenuAnchor(
            style: compactMenuStyle(context),
            // A small gap below the button, rather than the menu opening
            // flush against it — same idea as submenuGap for a cascading
            // submenu, just vertical instead of horizontal here.
            alignmentOffset: const Offset(0, AppSizes.spacing8),
            menuChildren: [
              for (final item in menuItems)
                _SplitButtonMenuItem(
                  label: item.label,
                  onPressed: () => onMenuItemSelected(item.value),
                ),
            ],
            builder: (context, controller, child) {
              final chevron = _SplitButtonChevron(
                height: height,
                loading: loading || disabled,
                foreground: effectiveForeground,
                controller: controller,
              );
              return menuTooltip == null
                  ? chevron
                  : Tooltip(message: menuTooltip, child: chevron);
            },
          ),
        ],
      ),
    );
  }
}

/// The main body's icon/spinner + label content, split out purely to keep
/// [SplitButton.build] within this file's own widget-nesting budget.
class _SplitButtonContent extends StatelessWidget {
  const _SplitButtonContent({
    required this.height,
    required this.loading,
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final double height;
  final bool loading;
  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Same reasoning as CircleIconButton/PrimaryButton's own
            // icon/spinner swap — crossfades instead of snapping between
            // two different widget types.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: loading
                  ? LoadingSpinner(
                      key: const ValueKey('spinner'),
                      // Matches the icon's own size below — LoadingSpinner
                      // otherwise defaults to iconSmall, 2px narrower than
                      // iconMedium, so the label next to it would visibly
                      // shift sideways over the crossfade as AnimatedSwitcher
                      // sizes itself to whichever child is momentarily
                      // larger.
                      size: AppSizes.iconMedium,
                      color: foreground,
                    )
                  : Icon(
                      icon,
                      key: const ValueKey('icon'),
                      size: AppSizes.iconMedium,
                      color: foreground,
                    ),
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: foreground,
                // Only affects digit glyphs (0-9), so this is a no-op
                // for the rest of a typical label ("Install ") — but
                // it keeps a version number's own width from jittering
                // between different digits (FVM Manager's install
                // button relies on this so the button doesn't
                // visibly resize every time the selected version
                // changes, e.g. between its loading placeholder and
                // a real version, or between two real versions).
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One dropdown entry, split out purely to keep [SplitButton.build] within
/// this file's own widget-nesting budget.
class _SplitButtonMenuItem extends StatelessWidget {
  const _SplitButtonMenuItem({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      style: compactMenuButtonStyle(context),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// The dropdown's chevron trigger, split out purely to keep the
/// [MenuAnchor.builder] closure within this file's own widget-nesting
/// budget.
class _SplitButtonChevron extends StatelessWidget {
  const _SplitButtonChevron({
    required this.height,
    required this.loading,
    required this.foreground,
    required this.controller,
  });

  final double height;
  final bool loading;
  final Color foreground;
  final MenuController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 36,
      child: InkWell(
        onTap: loading
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
        child: Center(
          child: Icon(
            CupertinoIcons.chevron_down,
            size: AppSizes.iconSmall,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
