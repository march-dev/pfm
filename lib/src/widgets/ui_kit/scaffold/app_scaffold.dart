import 'package:flutter/material.dart';

/// The plain `Scaffold(body: SafeArea(child: ...))` shell every top-level
/// screen in the app starts from — pulled out only so that shape is
/// declared once instead of repeated verbatim in each screen file.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: body));
  }
}

/// [AppScaffold] plus the `CallbackShortcuts(child: Focus(child: ...))`
/// wrapper several top-level screens (dashboard, explorer, storage,
/// settings, system_cleaner) repeat verbatim around it, to give F5 a
/// screen-specific action — pulled out for the same reason as
/// [AppScaffold] itself: declared once rather than 3 levels deep in every
/// screen's own build().
///
/// [focusNode] is still each screen's own _ScaffoldState field, requested/
/// unfocused as its tab is selected/deselected (see e.g. system_cleaner.
/// screen.dart's own _ScaffoldState) — CallbackShortcuts only intercepts
/// key events reaching a focused descendant, and _RootScaffold keeps every
/// screen mounted at once (an IndexedStack, not a Navigator swap), so that
/// lifecycle is what keeps F5 firing only for the actually-visible tab.
class ShortcutScaffold extends StatelessWidget {
  const ShortcutScaffold({
    super.key,
    required this.focusNode,
    required this.bindings,
    required this.body,
  });

  final FocusNode focusNode;
  final Map<ShortcutActivator, VoidCallback> bindings;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(focusNode: focusNode, child: AppScaffold(body: body)),
    );
  }
}
