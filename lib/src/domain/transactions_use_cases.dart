import '../../pfm.dart';

/// Business logic for reading and changing the stored transactions,
/// including the hand-entered cash operations.
class TransactionsUseCases {
  const TransactionsUseCases(this._repo, this._l10n);

  final TransactionsRepo _repo;
  final AppLocalizations _l10n;

  List<TransactionModel> getAll() {
    try {
      return _repo.getAll();
    } catch (error, stackTrace) {
      logError('Load transactions', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadData);
      return [];
    }
  }

  /// Records cash put into ([amountCents] > 0) or taken out of
  /// ([amountCents] < 0) the account by hand. Returns the stored entry, or
  /// null if it couldn't be saved.
  Future<TransactionModel?> addCashOperation({
    required DateTime date,
    required int amountCents,
    String note = '',
  }) async {
    final trimmed = note.trim();
    final tx = TransactionModel(
      id: 'cash_${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime(date.year, date.month, date.day),
      description: trimmed.isNotEmpty
          ? trimmed
          : amountCents > 0
              ? _l10n.cashInsertedDescription
              : _l10n.cashWithdrawnDescription,
      amountCents: amountCents,
      source: TransactionSource.manualCash,
    );
    try {
      await _repo.addNew([tx]);
      return tx;
    } catch (error, stackTrace) {
      logError('Add cash operation', error, stackTrace);
      SnackbarManager.show(_l10n.errorAddCash);
      return null;
    }
  }

  Future<bool> delete(TransactionModel tx) async {
    try {
      await _repo.delete(tx.id);
      return true;
    } catch (error, stackTrace) {
      logError('Delete transaction "${tx.description}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorDeleteTransaction);
      return false;
    }
  }
}
