import 'dart:io';

import '../../pfm.dart';

/// Thin wrapper around [ErrorLogRepo] — see its own doc. No failure here is
/// worth its own try/catch + snackbar: [setFileLoggingEnabled] only flips
/// an in-memory flag (can't throw in practice), and [logsDirectory] is a
/// plain read; actually opening it in the OS file manager goes through
/// [FileManagerUseCases.reveal] instead, which has its own handling.
class ErrorLogUseCases {
  const ErrorLogUseCases(this._repo);

  final ErrorLogRepo _repo;

  Directory get logsDirectory => _repo.logsDirectory;

  void setFileLoggingEnabled(bool enabled) => _repo.setEnabled(enabled);
}
