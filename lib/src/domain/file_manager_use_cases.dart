import 'dart:io';

import '../../pfm.dart';

/// Business logic for showing a folder to the user in the OS file manager.
class FileManagerUseCases {
  const FileManagerUseCases(this._repo);

  final FileManagerRepo _repo;

  Future<void> reveal(String path) async {
    try {
      await _repo.reveal(path);
    } on ProcessException {
      // No native file manager launcher available on PATH; nothing we
      // can do.
    } catch (error, stackTrace) {
      logError('Reveal "$path" in file manager', error, stackTrace);
    }
  }
}
