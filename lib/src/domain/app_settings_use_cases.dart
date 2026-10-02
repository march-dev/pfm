import '../../pfm.dart';

/// Business logic for the small standalone preferences persisted across
/// launches. Every write here is just a preference save that already
/// applied in memory regardless of whether it persists — so a failure is
/// only worth logging, never worth a snackbar.
class AppSettingsUseCases {
  const AppSettingsUseCases(this._repo);

  final AppSettingsRepo _repo;

  bool getFileLoggingEnabled() => _repo.getFileLoggingEnabled();

  Future<void> setFileLoggingEnabled(bool value) async {
    try {
      await _repo.setFileLoggingEnabled(value);
    } catch (error, stackTrace) {
      logError('Save file logging preference', error, stackTrace);
    }
  }
}
