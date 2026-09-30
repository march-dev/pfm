import '../../pfm.dart';

class ImportOutcome {
  const ImportOutcome({
    required this.fileName,
    required this.added,
    required this.duplicates,
    required this.skipped,
  });

  final String fileName;

  /// Transactions that weren't stored before.
  final int added;

  /// Rows already imported earlier (an overlapping statement).
  final int duplicates;

  /// Rows under the table header that weren't transactions.
  final int skipped;
}

/// Business logic for importing a Santander statement file.
class StatementImportUseCases {
  const StatementImportUseCases(
    this._picker,
    this._parser,
    this._transactions,
    this._l10n,
  );

  final StatementPickerRepo _picker;
  final SantanderStatementParser _parser;
  final TransactionsRepo _transactions;
  final AppLocalizations _l10n;

  /// Null if the user cancelled the picker or the import failed (in which
  /// case they've already been told why).
  Future<ImportOutcome?> importStatement() async {
    try {
      final file = await _picker.pick();
      if (file == null) return null;

      final parsed = _parser.parse(file.bytes);
      final added = await _transactions.addNew(parsed.transactions);
      return ImportOutcome(
        fileName: file.name,
        added: added,
        duplicates: parsed.transactions.length - added,
        skipped: parsed.skippedRows,
      );
    } on StatementFormatException catch (error, stackTrace) {
      logError('Import statement (unrecognised format)', error, stackTrace);
      SnackbarManager.show(_l10n.errorImportFormat);
      return null;
    } catch (error, stackTrace) {
      logError('Import statement', error, stackTrace);
      SnackbarManager.show(_l10n.errorImportStatement);
      return null;
    }
  }
}
