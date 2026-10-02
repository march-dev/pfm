import 'dart:io';

import 'package:flutter/foundation.dart';

/// Logs a caught error/exception in a consistent, readable shape — used
/// wherever an operation fails, alongside showing the user a short
/// SnackbarManager message, so there's always a full error (and stack
/// trace, if given) in the console even though the user only ever sees a
/// one-line summary. Also appended to this session's own log file when
/// file logging is enabled (see ErrorLogRepo) — same action/error/
/// stackTrace, just persisted so a bug report can include more than
/// whatever's still scrolled back in the console.
void logError(String action, Object error, [StackTrace? stackTrace]) {
  debugPrint('┌─ Error: $action');
  debugPrint('│  $error');
  if (stackTrace != null) {
    for (final line in stackTrace.toString().trimRight().split('\n')) {
      debugPrint('│  $line');
    }
  }
  debugPrint('└─');
  _appendToSessionLogFile(action, error, stackTrace);
}

// File logging is entirely optional (ErrorLogRepo.init decides whether it
// starts enabled, from the user's own persisted preference) and reached
// through this module's own private global state rather than threaded in
// as a parameter — logError is called from deep inside repos/use-cases
// with no BuildContext/DI of its own, by design, so anything it writes to
// has to be reachable the same dependency-free way. ErrorLogRepo is the
// only thing that ever calls [initSessionLogFile]/[setFileLoggingEnabled]
// below — everything else (Settings' own toggle, the "open logs folder"
// button) goes through that repo like any other setting, the same as the
// rest of this app's architecture.

/// Total bytes every past session's own log file may add up to — enforced
/// (oldest session first) once per launch in [initSessionLogFile], not
/// continuously, plus a per-write check below so one single pathological
/// session logging nonstop can't itself grow past this on its own.
const maxLogBytes = 10 * 1024 * 1024;

File? _sessionLogFile;
bool _fileLoggingEnabled = false;

/// Creates this run's own log file (named from [launchTime], so every
/// session gets a distinct one) under [logsDirectory] and prunes older
/// sessions' own files (oldest first) until the directory's total size is
/// back under [maxLogBytes]. Called once per app launch, regardless of
/// whether file logging actually starts [enabled], so toggling it on
/// mid-session always has somewhere ready to write without needing to redo
/// this setup.
Future<File> initSessionLogFile(
  Directory logsDirectory,
  DateTime launchTime, {
  required bool enabled,
}) async {
  await logsDirectory.create(recursive: true);
  final name = launchTime.toIso8601String().replaceAll(RegExp('[:.]'), '-');
  final file = File('${logsDirectory.path}${Platform.pathSeparator}'
      'session_$name.log');
  await _pruneOldSessions(logsDirectory, keep: file);
  _sessionLogFile = file;
  _fileLoggingEnabled = enabled;
  return file;
}

/// Flips whether [logError] actually writes to this session's own log
/// file — the live effect of Settings' own toggle, independent of (and
/// faster than) persisting that choice via AppSettingsUseCases.
void setFileLoggingEnabled(bool enabled) => _fileLoggingEnabled = enabled;

Future<void> _pruneOldSessions(Directory dir, {required File keep}) async {
  try {
    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path != keep.path)
        .cast<File>()
        .toList();
    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    var total = 0;
    for (final file in files) {
      total += await file.length();
    }
    for (final file in files) {
      if (total <= maxLogBytes) break;
      total -= await file.length();
      await file.delete();
    }
  } catch (_) {
    // Pruning failing isn't worth surfacing — worst case old sessions'
    // own files just stick around a while longer than the cap intends.
  }
}

void _appendToSessionLogFile(
  String action,
  Object error,
  StackTrace? stackTrace,
) {
  final file = _sessionLogFile;
  if (!_fileLoggingEnabled || file == null) return;
  try {
    if (file.existsSync() && file.lengthSync() >= maxLogBytes) return;
    final buffer = StringBuffer()
      ..writeln('[${DateTime.now().toIso8601String()}] $action')
      ..writeln(error.toString());
    if (stackTrace != null) {
      buffer.writeln(stackTrace.toString().trimRight());
    }
    buffer.writeln();
    file.writeAsStringSync(
      buffer.toString(),
      mode: FileMode.append,
      flush: false,
    );
  } catch (_) {
    // File logging failing must never break the (already-happened)
    // console log/error report this is only ever piggybacking on.
  }
}
