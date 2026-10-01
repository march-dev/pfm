import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The basic single-line text input shared across the app — [SearchField]
/// and the New/Rename Collection dialog both build on this rather than
/// each wiring up their own styled [TextField], so every text field in
/// the app looks and behaves the same by construction.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// An inline action/icon at the field's start (e.g. [SearchField]'s
  /// search glyph) — sized via [prefixIconConstraints].
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;

  /// An inline action/icon at the field's end (e.g. [SearchField]'s clear
  /// button) — sized via [suffixIconConstraints].
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;

  final EdgeInsetsGeometry? contentPadding;

  // Filled with the scaffold background (rather than the theme's default
  // fill) so this sits flush with the page instead of reading as a
  // separate floating panel, with an explicit enabled/focused border —
  // otherwise focusing it pulls in the theme's default focused-border
  // color (typically a bright accent), which can read far louder than
  // whatever sits next to it. Focused is just a lightened step of the
  // same outline (not a different hue), so it reads as "this field is
  // active" without shouting.
  // The outline is drawn around the text plus this padding — constraints
  // alone only centre a text-hugging outline inside a taller box — so the
  // vertical padding is whatever tops the real line height up to the shared
  // control height. Measured rather than assumed, since the line height
  // depends on the theme's font metrics. Stays single-line (unlike
  // `expands`, which would turn Enter into a newline instead of a submit).
  static EdgeInsets _defaultPadding(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final vertical =
        ((AppSizes.controlHeight - painter.height) / 2).clamp(0.0, 16.0);
    painter.dispose();
    return EdgeInsets.symmetric(
      horizontal: AppSizes.spacing12,
      vertical: vertical,
    );
  }

  InputDecoration _decoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      hintText: hintText,
      hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      border: border(colorScheme.outline),
      enabledBorder: border(colorScheme.outline),
      focusedBorder: border(
        Color.lerp(colorScheme.outline, colorScheme.onSurface, 0.4)!,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
      constraints:
          const BoxConstraints.tightFor(height: AppSizes.controlHeight),
      contentPadding: contentPadding ?? _defaultPadding(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    // InputDecorator shrinks by the theme's visual density, which is compact
    // on desktop — a field padded to AppSizes.controlHeight would paint 8px
    // short on macOS. Pinning standard keeps the height platform-independent.
    return Theme(
      data: Theme.of(context).copyWith(visualDensity: VisualDensity.standard),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlignVertical: TextAlignVertical.center,
        decoration: _decoration(context),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        // Otherwise a tap outside leaves the field focused, pulling in the
        // theme's default focused-border color until something else steals
        // focus instead.
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
