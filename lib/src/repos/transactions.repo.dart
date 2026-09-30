import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../services.dart';

/// Every transaction ever imported or entered by hand, one Hive entry per
/// transaction keyed by its id — so re-importing an overlapping statement
/// is a plain "skip keys that already exist".
class TransactionsRepo {
  const TransactionsRepo({required Box box, required FinanceCodec codec})
      : _box = box,
        _codec = codec;

  final Box _box;
  final FinanceCodec _codec;

  List<TransactionModel> getAll() => [
        for (final json in _box.values.cast<String>())
          _codec.decodeTransaction(json),
      ];

  /// Stores every transaction not already present; returns how many were
  /// new. Existing entries are left untouched, so a re-import never
  /// overwrites anything.
  Future<int> addNew(Iterable<TransactionModel> transactions) async {
    final fresh = {
      for (final tx in transactions)
        if (!_box.containsKey(tx.id)) tx.id: _codec.encodeTransaction(tx),
    };
    await _box.putAll(fresh);
    return fresh.length;
  }

  Future<void> delete(String id) => _box.delete(id);
}
