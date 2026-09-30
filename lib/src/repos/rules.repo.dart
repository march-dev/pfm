import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../services.dart';

/// The user's "exact name" and pattern rules — one small list in the
/// durable settings box.
class RulesRepo {
  const RulesRepo({required Box box, required FinanceCodec codec})
      : _box = box,
        _codec = codec;

  final Box _box;
  final FinanceCodec _codec;

  static const _key = 'rulesKey';

  List<CategoryRule> getAll() {
    final json = _box.get(_key) as String?;
    return json == null ? [] : _codec.decodeRules(json);
  }

  Future<void> saveAll(List<CategoryRule> rules) =>
      _box.put(_key, _codec.encodeRules(rules));
}
