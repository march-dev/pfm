import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The app's own on/off toggle — a plain [Switch] (in the theme's primary
/// color) scaled down to [AppSizes.controlHeight], 32px tall, matching the
/// height every other row-action control already uses in a
/// [HeaderCard]'s own `actions` row (CircleIconButton/PrimaryButton/
/// SplitButton all read 32px there). Material's own smallest supported
/// footprint — [MaterialTapTargetSize.shrinkWrap] with zero padding — is
/// still [_naturalSize] (52x40), visibly taller than those neighbours, so
/// this scales the whole thing down via [FittedBox] rather than trying to
/// coax Switch's own layout into a shorter size directly.
///
/// Bundled here once so a call site just needs `AppSwitch(value:,
/// onChanged:)` — the same two bare parameters a plain [Switch] needs —
/// with every other visual decision (size, color) already made.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  // Switch's own smallest supported footprint (shrinkWrap tap target,
  // zero padding) — see this class's own doc.
  static const _naturalSize = Size(52, 40);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlHeight,
      width: AppSizes.controlHeight * _naturalSize.width / _naturalSize.height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
