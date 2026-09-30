import 'package:flutter/material.dart';

import 'pfm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  final dependencies = await DependencyResolver.create();

  // The stores that need an AppLocalizations aren't built here — there's no
  // BuildContext yet. See _RootScaffoldState.build() (app.dart), the first
  // point one exists.
  runApp(App(dependencies: dependencies));
}
