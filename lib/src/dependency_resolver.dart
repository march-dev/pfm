import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../pfm.dart';

// Durable, user-authored data: rules, one-off assignments, custom
// categories. Small and fixed-key — nothing here is safe to casually lose.
const _settingsBoxName = 'settings';

// Every imported / hand-entered transaction, one entry each. Kept in its
// own box so this bulk data (which grows with every import) never bloats,
// or shares a fate with, the small settings box.
const _transactionsBoxName = 'transactions';

/// Opens [name], recovering once from a corrupted box file (rather than
/// crashing at launch with no way back in) by deleting and recreating it.
///
/// Only [HiveError] (a genuinely corrupted file) triggers that destructive
/// recovery — deliberately NOT a blanket catch: opening a box also throws a
/// plain FileSystemException when another instance of the app has it
/// locked, and deleting the box then would wipe a perfectly good one out
/// from under whichever instance owns it.
Future<Box> _openBox(String name) async {
  try {
    return await Hive.openBox(name);
  } on HiveError catch (error, stackTrace) {
    logError(
      'Open $name box (corrupted, deleting and recreating it)',
      error,
      stackTrace,
    );
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox(name);
  }
}

/// The app's single composition root: opens the Hive boxes, then constructs
/// every repo in dependency order, wiring each one's own dependencies in
/// explicitly through its constructor. Nothing downstream reaches for a repo
/// via an ambient singleton — main.dart builds one [DependencyResolver],
/// and every store gets the specific repos it needs from it (see app.dart).
class DependencyResolver {
  const DependencyResolver._({
    required this.codec,
    required this.statementParser,
    required this.transactionsRepo,
    required this.rulesRepo,
    required this.assignmentsRepo,
    required this.customCategoriesRepo,
    required this.statementPickerRepo,
  });

  static Future<DependencyResolver> create() async {
    // Application Support rather than Hive.initFlutter()'s default of
    // ~/Documents: on macOS that is one of the folders TCC privacy
    // protections gate behind per-app consent, which can silently lapse and
    // then crash the app at launch before any box even opens.
    final supportDir = await getApplicationSupportDirectory();
    Hive.init(supportDir.path);
    final settingsBox = await _openBox(_settingsBoxName);
    final transactionsBox = await _openBox(_transactionsBoxName);

    const codec = FinanceCodec();
    const statementParser = SantanderStatementParser();
    const statementPickerRepo = StatementPickerRepo();
    final transactionsRepo = TransactionsRepo(box: transactionsBox, codec: codec);
    final rulesRepo = RulesRepo(box: settingsBox, codec: codec);
    final assignmentsRepo = AssignmentsRepo(box: settingsBox);
    final customCategoriesRepo = CustomCategoriesRepo(box: settingsBox, codec: codec);

    return DependencyResolver._(
      codec: codec,
      statementParser: statementParser,
      transactionsRepo: transactionsRepo,
      rulesRepo: rulesRepo,
      assignmentsRepo: assignmentsRepo,
      customCategoriesRepo: customCategoriesRepo,
      statementPickerRepo: statementPickerRepo,
    );
  }

  final FinanceCodec codec;
  final SantanderStatementParser statementParser;
  final TransactionsRepo transactionsRepo;
  final RulesRepo rulesRepo;
  final AssignmentsRepo assignmentsRepo;
  final CustomCategoriesRepo customCategoriesRepo;
  final StatementPickerRepo statementPickerRepo;
}
