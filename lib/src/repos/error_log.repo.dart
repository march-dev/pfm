import 'dart:io';

import '../utils/error_logging.util.dart';

/// Persists caught errors (see error_logging.util.dart's own [logError]) to
/// a plain-text file under this app's own [logsDirectory] — one file per
/// app session (process launch) — so a bug report can include more than
/// whatever's still scrolled back in the console. On by default (see
/// [init]'s own `enabled`), but still a user-disableable preference, not
/// mandatory; total size across every session's own file is kept under
/// 10MB by deleting the oldest ones first (see error_logging.util.dart's
/// own maxLogBytes/initSessionLogFile, which this just wraps so the rest
/// of the app reaches it the same repo-layer way as every other setting/
/// action).
class ErrorLogRepo {
  ErrorLogRepo({required this.logsDirectory});

  final Directory logsDirectory;

  /// Creates this session's own log file and prunes older ones down to the
  /// size cap — call once at startup, after the user's persisted [enabled]
  /// preference is known. Never throws — a failure here (e.g. a read-only
  /// disk) should mean "no file logging this run", not "the app can't
  /// start".
  Future<void> init({required bool enabled}) async {
    try {
      await initSessionLogFile(logsDirectory, DateTime.now(), enabled: enabled);
    } catch (_) {
      // See this method's own doc — logging its own setup failure would
      // need the very file logging that just failed to set up.
    }
  }

  /// The live effect of Settings' own toggle — see [setFileLoggingEnabled]'s
  /// own doc for why this is separate from persisting the choice.
  void setEnabled(bool enabled) => setFileLoggingEnabled(enabled);
}
