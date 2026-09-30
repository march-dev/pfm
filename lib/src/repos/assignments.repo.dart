import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// One-off "this transaction is category X" overrides: transaction id ->
/// category id, as a single map in the durable settings box.
class AssignmentsRepo {
  const AssignmentsRepo({required Box box}) : _box = box;

  final Box _box;

  static const _key = 'assignmentsKey';

  Map<String, String> getAll() {
    final json = _box.get(_key) as String?;
    return json == null
        ? {}
        : (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
  }

  Future<void> saveAll(Map<String, String> assignments) =>
      _box.put(_key, jsonEncode(assignments));
}
