import 'package:hive_flutter/hive_flutter.dart';

/// The small, standalone preferences persisted across launches. Grouped
/// together because each is just a trivial key-value read/write with no
/// logic of its own.
class AppSettingsRepo {
  const AppSettingsRepo({required Box box}) : _box = box;

  final Box _box;

  static const _fileLoggingEnabledKey = 'fileLoggingEnabledKey';

  /// On by default — useful enough for diagnosing a reported bug that it's
  /// worth having on from the first launch rather than only after a user
  /// thinks to turn it on themselves; still a disableable preference, not
  /// mandatory, via the switch itself.
  bool getFileLoggingEnabled() =>
      (_box.get(_fileLoggingEnabledKey) as bool?) ?? true;

  Future<void> setFileLoggingEnabled(bool value) async {
    await _box.put(_fileLoggingEnabledKey, value);
  }
}
